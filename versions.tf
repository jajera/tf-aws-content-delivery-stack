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
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  # Explicitly set S3 endpoint to us-east-1 to prevent region detection issues
  # This is critical for WAF logs bucket which MUST be in us-east-1
  endpoints {
    s3 = "https://s3.us-east-1.amazonaws.com"
  }

  default_tags {
    tags = var.tags
  }
}
