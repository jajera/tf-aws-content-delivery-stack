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

  # Enable ALB and ECS
  enable_alb = true
  enable_ecs = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

output "web_alb_url" {
  description = "HTTP URL of the Web ALB"
  value       = module.content_delivery_stack.web_alb_url
}

output "api_alb_url" {
  description = "HTTP URL of the API ALB"
  value       = module.content_delivery_stack.api_alb_url
}
