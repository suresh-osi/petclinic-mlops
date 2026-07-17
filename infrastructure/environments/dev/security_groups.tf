resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  name        = var.alb_security_group_name
  description = "Security group for ALB"

  ingress {
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.alb_egress_cidr]
  }

  tags = {
    Name        = var.alb_security_group_name
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  name        = var.ec2_security_group_name
  description = "Security group for EC2 instances"

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ec2_egress_cidr]
  }

  tags = {
    Name        = var.ec2_security_group_name
    Environment = var.environment
  }
}
