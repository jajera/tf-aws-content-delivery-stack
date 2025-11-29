# ALB Module

This module creates Application Load Balancers (ALBs) for routing traffic to ECS services, along with target groups, listeners, security groups, and S3 bucket for access logs.

## Features

- Two ALBs: one for API traffic (port 8000) and one for Web traffic (port 80)
- Target groups with health checks
- HTTP and HTTPS listeners (HTTPS optional with ACM certificate)
- Automatic HTTP to HTTPS redirect when certificate is provided and `enable_https` is true
- Security groups allowing HTTP/HTTPS from internet
- S3 bucket for ALB access logs with lifecycle policies for cost optimization
- Cross-zone load balancing enabled
- HTTP/2 enabled

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  name_prefix       = "my-app"
  name_suffix       = random_id.suffix.hex
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  aws_region        = "ap-southeast-2"

  # Optional: Enable HTTPS with ACM certificate
  alb_certificate_arn = aws_acm_certificate.alb.arn
  enable_https        = true

  enable_deletion_protection = false
  force_destroy             = false

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
| name_suffix | Suffix for resource names (typically random ID) | string | - | yes |
| vpc_id | ID of the VPC | string | - | yes |
| public_subnet_ids | List of public subnet IDs for ALB placement | list(string) | - | yes |
| aws_region | AWS region | string | - | yes |
| alb_certificate_arn | ARN of ACM certificate for ALB HTTPS listener (optional) | string | `null` | no |
| enable_https | If true and certificate is provided, redirect HTTP to HTTPS. If false or no certificate, HTTP listener will forward to target group | bool | `false` | no |
| enable_deletion_protection | Enable deletion protection for ALB | bool | `false` | no |
| force_destroy | If true, Terraform will not prevent destruction of resources | bool | `false` | no |
| tags | Tags to apply to all resources | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_alb_dns_name | DNS name of the API ALB |
| api_alb_arn | ARN of the API ALB |
| api_alb_zone_id | Zone ID of the API ALB |
| api_target_group_arn | ARN of the API target group |
| api_alb_security_group_id | ID of the API ALB security group |
| api_listener_arns | ARNs of API ALB listeners (for dependency management) |
| web_alb_dns_name | DNS name of the Web ALB |
| web_alb_arn | ARN of the Web ALB |
| web_alb_zone_id | Zone ID of the Web ALB |
| web_target_group_arn | ARN of the Web target group |
| web_alb_security_group_id | ID of the Web ALB security group |
| web_listener_arns | ARNs of Web ALB listeners (for dependency management) |

## Resources Created

### ALBs

- **API ALB**: Routes traffic to API services on port 8000
- **Web ALB**: Routes traffic to Web services on port 80

### Target Groups

- **API Target Group**: Health check on `/health` endpoint, port 8000
- **Web Target Group**: Health check on `/health` endpoint, port 80

### Listeners

- **HTTP Listeners**: Port 80
  - If `enable_https = true` and certificate provided: Redirects to HTTPS
  - Otherwise: Forwards to target group
- **HTTPS Listeners**: Port 443 (only created if certificate ARN provided)
  - Uses TLS 1.2/1.3 security policy
  - Forwards to target group

### Security Groups

- **API ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet
- **Web ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet

### S3 Bucket

- **ALB Access Logs Bucket**: Stores ALB access logs
  - Lifecycle policy: Transitions to STANDARD_IA after 30 days, GLACIER after 60 days, deletes after 90 days
  - Bucket policy allows ELB service account to write logs
