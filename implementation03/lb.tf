# The ingress for Taskly. We use a layer-7 load balancer to get path-based
# routing.
resource "aws_lb" "lb" {
  name_prefix     = "taskly"
  subnets         = data.aws_subnets.default.ids
  security_groups = [aws_security_group.lb.id]
}

# Security group for the load balancer.
resource "aws_security_group" "lb" {
  name_prefix = "taskly"
  description = "Security group for load balancer."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "HTTP"
    from_port        = var.ingress_port
    to_port          = var.ingress_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Load balancer listener. The default action forwards traffic to the frontend
# target group.
resource "aws_lb_listener" "lb" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.ingress_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Listern rule to forward /api traffic to the backend.
resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.lb.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
