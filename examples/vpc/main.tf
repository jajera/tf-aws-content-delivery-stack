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

module "vpc" {
  source = "../../modules/vpc"

  name_prefix             = "test"
  vpc_cidr                = "10.0.0.0/16"
  availability_zones      = ["ap-southeast-2a", "ap-southeast-2b"]
  subnet_bits             = 8
  nat_gateway_per_az      = true # false = cost effective (single NAT), true = resilient (NAT per AZ)
  flow_log_retention_days = 7
  force_destroy           = true # true = allows deletion of resources with data (e.g., CloudWatch Log Group)
}
