# Security Group for ALB - allows traffic from HTTP and HTTPS
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-${var.alb_name}-alb-sg"
  description = "Security group for ${var.alb_name} ALB - allows traffic from internet (HTTP and HTTPS)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.alb_name}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
