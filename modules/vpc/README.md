# VPC Module

This module creates a VPC with subnets, NAT gateways, route tables, and VPC Flow Logs.

## Features

- VPC with configurable CIDR
- Public subnets (for NAT Gateway placement)
- Private subnets with NAT Gateway for ECS tasks
- Internet Gateway and NAT Gateways
- Route tables and associations
- VPC Flow Logs to CloudWatch Logs

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix       = "my-app"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
  subnet_bits       = 8
  nat_gateway_per_az = true  # Set to false to save costs (single NAT Gateway)
  flow_log_retention_days = 7
  force_destroy     = false  # Set to true to allow Terraform to destroy resources

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| vpc_cidr | CIDR block for VPC | string | - | yes |
| availability_zones | List of availability zones | list(string) | - | yes |
| subnet_bits | Number of bits to add to VPC CIDR for subnet calculation | number | 8 | no |
| nat_gateway_per_az | If true, create one NAT Gateway per AZ (high availability). If false, create a single NAT Gateway (cost savings) | bool | true | no |
| flow_log_retention_days | Number of days to retain VPC Flow Logs | number | 7 | no |
| force_destroy | If true, Terraform will not prevent destruction of resources | bool | false | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| subnet_ids | IDs of subnets to use for ECS |
| nat_gateway_ids | IDs of NAT Gateways |
| nat_gateway_count | Number of NAT Gateways created |
| internet_gateway_id | ID of the Internet Gateway |
