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

module "content_delivery_stack" {
  source = "../.."

  name_prefix             = "test"
  aws_region              = "ap-southeast-2"
  vpc_cidr                = "10.0.0.0/16"
  availability_zones      = ["ap-southeast-2a", "ap-southeast-2b"]
  subnet_bits             = 8
  nat_gateway_per_az      = false # false = cost effective (single NAT), true = resilient (NAT per AZ)
  flow_log_retention_days = 7
  force_destroy           = true # true = allows deletion of resources with data (e.g., CloudWatch Log Group)

  # Enable ALB, ECS, and CloudFront
  enable_alb           = true
  enable_ecs           = true
  enable_cloudfront    = true
  enable_waf           = true
  enable_waf_logging   = true
  enable_custom_domain = true
  custom_domain_name   = var.custom_domain_name
  route53_zone_name    = var.route53_zone_name

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

output "cloudfront_url" {
  description = "HTTPS URL served via CloudFront (default domain) - use this URL to access the web application"
  value       = module.content_delivery_stack.cloudfront_url
}

output "cloudfront_api_url" {
  description = "HTTPS URL for API endpoints served via CloudFront (default domain) - use this URL to access the API"
  value       = module.content_delivery_stack.cloudfront_api_url
}

output "custom_domain_url" {
  description = "HTTPS URL for the custom domain - use this URL to access the web application"
  value       = module.content_delivery_stack.custom_domain_url
}

output "custom_domain_api_url" {
  description = "HTTPS URL for API endpoints via custom domain - use this URL to access the API"
  value       = module.content_delivery_stack.custom_domain_api_url
}
