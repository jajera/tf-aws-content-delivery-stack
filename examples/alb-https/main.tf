terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix             = "test"
  vpc_cidr                = "10.0.0.0/16"
  availability_zones      = ["ap-southeast-2a", "ap-southeast-2b"]
  subnet_bits             = 8
  nat_gateway_per_az      = false # false = cost effective (single NAT), true = resilient (NAT per AZ)
  flow_log_retention_days = 7
  force_destroy           = true # true = allows deletion of resources with data (e.g., CloudWatch Log Group)

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Shared S3 bucket for ALB access logs
# Optional for demo: Good to have for production but not essential for basic functionality.
# Enables ALB access logging to S3 for monitoring and troubleshooting HTTP requests.
# The ALB will work without this, but you won't have access logs for debugging.
module "alb_logs_s3" {
  source = "../../modules/alb/s3-logs"

  name_prefix   = "test"
  name_suffix   = random_id.suffix.hex
  aws_region    = "ap-southeast-2"
  force_destroy = true
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Route53 hosted zone data source (for certificate validation)
data "aws_route53_zone" "this" {
  name = var.route53_zone_name
}

# ACM Certificate for ALB HTTPS
resource "aws_acm_certificate" "alb" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "test-alb-cert"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Route53 records for ACM certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn = aws_acm_certificate.alb.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}

# Web ALB with HTTPS enabled
module "alb_web" {
  source = "../../modules/alb"

  name_prefix           = "test"
  name_suffix           = random_id.suffix.hex
  alb_name              = "web"
  target_port           = 80
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  aws_region            = "ap-southeast-2"
  access_logs_bucket_id = module.alb_logs_s3.bucket_id
  force_destroy         = true

  # HTTPS configuration
  alb_certificate_arn = aws_acm_certificate_validation.alb.certificate_arn
  enable_https        = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Route53 A record pointing custom domain to ALB
resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb_web.alb_dns_name
    zone_id                = module.alb_web.alb_zone_id
    evaluate_target_health = true
  }
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security group for EC2 instances - allows traffic from ALB
resource "aws_security_group" "ec2" {
  name        = "test-web-ec2-sg"
  description = "Security group for EC2 instances - allows traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb_web.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "test-web-ec2-sg"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# User data script to run a simple web server on Amazon Linux 2023
locals {
  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

# Get IMDSv2 token (valid for 6 hours)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)

# Fetch instance metadata using IMDSv2
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null)

# Create a simple HTML page with instance metadata
cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Web ALB Demo</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #2c3e50; }
        p { color: #7f8c8d; }
    </style>
</head>
<body>
    <h1>Web ALB is Working!</h1>
    <p>This is a demo response from an EC2 instance behind the Application Load Balancer.</p>
    <p>Instance ID: $${INSTANCE_ID}</p>
    <p>Availability Zone: $${AVAILABILITY_ZONE}</p>
</body>
</html>
HTML

# Create health check endpoint
echo "OK" > /var/www/html/health
chmod 644 /var/www/html/health
EOF
}

# EC2 instances in private subnets (one per AZ)
resource "aws_instance" "web" {
  count = length(module.vpc.private_subnet_ids)

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnet_ids[count.index]
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true

  tags = {
    Name        = "test-web-${count.index + 1}"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Register EC2 instances with ALB target group (using private IP for target_type = "ip")
resource "aws_lb_target_group_attachment" "web" {
  count = length(aws_instance.web)

  target_group_arn = module.alb_web.target_group_arn
  target_id        = aws_instance.web[count.index].private_ip
  port             = 80
}

output "alb_url" {
  description = "HTTPS URL of the Web ALB - use this URL to access the demo application (HTTP requests will be redirected to HTTPS)"
  value       = format("https://%s", module.alb_web.alb_dns_name)
}

output "route53_url" {
  description = "HTTPS URL of the custom domain via Route53 - use this URL to access the demo application (HTTP requests will be redirected to HTTPS)"
  value       = format("https://%s", var.domain_name)
}
