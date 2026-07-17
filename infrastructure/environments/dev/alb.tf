resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

resource "aws_lb_target_group" "tg" {
  name_prefix = "tg-"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = var.health_check_path
    timeout             = 6
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = var.target_group_name
    Environment = var.environment
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.petclinic.id
  port             = var.app_port
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn

  port     = var.alb_listener_port
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
