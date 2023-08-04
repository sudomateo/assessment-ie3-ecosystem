# Security group for the frontend service.
resource "aws_security_group" "frontend" {
  name_prefix = "taskly-frontend"
  description = "Security group for taskly frontend."
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
    description     = "Taskly frontend port."
    from_port       = var.frontend_port
    to_port         = var.frontend_port
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
    "Component"   = "frontend"
  }
}

resource "aws_launch_template" "frontend" {
  name_prefix            = "taskly-frontend"
  description            = "Launch template for taskly frontend."
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.frontend.id]
  update_default_version = true
  user_data = base64encode(templatefile("${path.module}/templates/taskly.tmpl",
    {
      app_image = "sudomateo/taskly-frontend:${var.frontend_tag}"
      app_port  = var.frontend_port
    }
  ))

  tags = {
    "Application" = "taskly"
    "Component"   = "frontend"
  }
}

resource "aws_autoscaling_group" "frontend" {
  name_prefix         = "taskly-frontend"
  min_size            = 1
  max_size            = 1
  health_check_type   = "ELB"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.frontend.arn]

  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
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
    value               = "frontend"
    propagate_at_launch = true
  }
}

# Place frontend instances in their own target group.
resource "aws_lb_target_group" "frontend" {
  name_prefix = "taskly"
  target_type = "instance"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
  }

  tags = {
    "Application" = "taskly"
    "Component"   = "frontend"
  }
}
