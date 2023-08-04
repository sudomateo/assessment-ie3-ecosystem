resource "aws_security_group" "backend" {
  name_prefix = "taskly-backend"
  description = "Security group for taskly backend."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "Taskly backend port."
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Application" = "taskly"
    "Component"   = "backend"
  }
}

resource "aws_launch_template" "backend" {
  name_prefix            = "taskly-backend"
  description            = "Launch template for taskly backend."
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]
  update_default_version = true
  user_data = base64encode(templatefile("${path.module}/templates/taskly.tmpl",
    {
      app_image = "sudomateo/taskly-backend:${var.backend_tag}"
      app_port  = var.backend_port
    }
  ))

  tags = {
    "Application" = "taskly"
    "Component"   = "backend"
  }
}

resource "aws_autoscaling_group" "backend" {
  name_prefix         = "taskly-backend"
  min_size            = 1
  max_size            = 1
  health_check_type   = "ELB"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.backend.arn]

  launch_template {
    id      = aws_launch_template.backend.id
    version = aws_launch_template.backend.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Application"
    value               = "taskly"
    propagate_at_launch = true
  }

  tag {
    key                 = "Component"
    value               = "backend"
    propagate_at_launch = true
  }
}

# Place backend instances in their own target group.
resource "aws_lb_target_group" "backend" {
  name_prefix = "taskly"
  target_type = "instance"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    enabled  = true
    path     = "/api/health"
    protocol = "HTTP"
  }

  tags = {
    "Application" = "taskly"
    "Component"   = "backend"
  }
}
