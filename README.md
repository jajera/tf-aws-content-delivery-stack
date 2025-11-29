# AWS Content Delivery Stack

![GitHub Actions](https://github.com/jajera/tf-aws-content-delivery-stack/actions/workflows/terraform-lint-validate.yml/badge.svg)
![GitHub Actions](https://github.com/jajera/tf-aws-content-delivery-stack/actions/workflows/terraform-tag-and-release.yml/badge.svg)

Terraform project demonstrating an AWS Networking & Content Delivery stack with CloudFront, WAF, S3, ALB, and ECS Fargate for secure, edge-optimized web and API delivery.

## Overview

This Terraform module creates an AWS infrastructure stack with:

- **VPC** with public/private subnets, NAT gateways, and VPC Flow Logs
- **Application Load Balancers (ALB)** for routing traffic to containerized services
- **ECS Fargate** for running containerized applications
- **CloudFront** CDN for global content delivery and caching
- **WAF** with rate limiting and HTTP method restrictions
- **S3** buckets for static assets and logging
- **Custom Domain** support with ACM certificates and Route53 DNS

## Architecture

```text
Internet
   │
   ├─→ CloudFront (CDN + WAF)
   │      │
   │      ├─→ S3 (Static Assets)
   │      ├─→ Web ALB → ECS Web Service
   │      └─→ API ALB → ECS API Service
   │
   └─→ ALB (Direct Access)
          │
          ├─→ Web ALB → ECS Web Service
          └─→ API ALB → ECS API Service
```

## Features

### Core Infrastructure

- **VPC** with configurable CIDR, multi-AZ support, and NAT gateways
- **Public/Private Subnets** for secure network segmentation
- **VPC Flow Logs** for network traffic monitoring

### Load Balancing

- **Dual ALBs**: Separate load balancers for web and API traffic
- **HTTPS Support**: Optional ACM certificate integration with HTTP→HTTPS redirect
- **Health Checks**: Automatic health monitoring and traffic routing
- **Access Logging**: ALB access logs stored in S3 with lifecycle policies

### Container Orchestration

- **ECS Fargate**: Serverless container execution
- **Auto-scaling**: Configurable task counts and resource allocation
- **CloudWatch Logs**: Centralized logging with configurable retention
- **Container Insights**: Optional enhanced monitoring

### Content Delivery

- **CloudFront CDN**: Global edge caching for static and dynamic content
- **Cache Behaviors**: Optimized caching policies for different content types
- **S3 Origin**: Static asset delivery from S3
- **Custom Domain**: Optional custom domain with ACM and Route53

### Security

- **WAF v2**: Web Application Firewall with:
  - Rate limiting per IP address
  - HTTP method restrictions
  - Optional logging to S3
- **Security Groups**: Network-level access control
- **HTTPS/TLS**: End-to-end encryption support

### Observability

- **CloudWatch Logs**: Centralized logging for ECS, VPC, and ALB
- **Access Logs**: ALB and CloudFront access logs in S3
- **WAF Logs**: Optional WAF traffic logging

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS Provider** >= 6.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create:
  - VPC, EC2, ECS, ALB, CloudFront, WAF, S3, Route53, ACM resources
- **Route53 Hosted Zone** (if using custom domain)

## Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd tf-aws-content-delivery-stack
   ```

2. **Copy example variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Configure variables**
   Edit `terraform.tfvars` with your settings:

   ```hcl
   name_prefix = "my-app"
   aws_region  = "ap-southeast-2"

   # Enable modules
   enable_alb        = true
   enable_ecs        = true
   enable_cloudfront = true
   ```

4. **Initialize Terraform**

   ```bash
   terraform init
   ```

5. **Plan and apply**

   ```bash
   terraform plan
   terraform apply
   ```

## Module Structure

The project is organized into reusable modules:

```text
.
├── modules/
│   ├── vpc/          # VPC, subnets, NAT gateways, flow logs
│   ├── alb/          # Application Load Balancers, target groups, listeners
│   ├── ecs/          # ECS cluster, services, task definitions, security groups
│   ├── cloudfront/   # CloudFront distribution, WAF, S3 origins
│   └── s3/           # Reusable S3 bucket module
├── main.tf           # Root module orchestrating all sub-modules
├── variables.tf      # Root-level input variables
├── outputs.tf        # Root-level outputs
└── terraform.tfvars.example  # Example configuration
```

### Module Dependencies

Modules have strict dependency chains enforced by validation:

1. **VPC** (always created) → Foundation for all networking
2. **ALB** (`enable_alb = true`) → Requires VPC
3. **ECS** (`enable_ecs = true`) → Requires ALB
4. **CloudFront** (`enable_cloudfront = true`) → Requires ALB

**Note**: CloudFront can be enabled independently of ECS if you only need static content delivery.

## Configuration

### Module Enable Switches

Control which modules are created:

```hcl
enable_alb        = true  # Create ALBs (requires VPC)
enable_ecs        = true  # Create ECS services (requires ALB)
enable_cloudfront = true  # Create CloudFront (requires ALB)
```

### VPC Configuration

```hcl
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
subnet_bits        = 8
nat_gateway_per_az = true  # false = single NAT Gateway (cost savings)
flow_log_retention_days = 7
```

### ALB Configuration

```hcl
alb_certificate_arn = "arn:aws:acm:..."  # Optional: Enable HTTPS
enable_https        = true                # Redirect HTTP to HTTPS
enable_deletion_protection = false
```

### CloudFront Configuration

```hcl
default_root_object = "index.html"
price_class         = "PriceClass_All"  # PriceClass_200 or PriceClass_100 for cost savings
alb_origin_protocol_policy = "https-only"
enable_s3_versioning = false
enable_cloudfront_access_logs = true
```

### WAF Configuration

```hcl
waf_rate_limit     = 2000  # Requests per 5-minute period per IP (0 = disabled)
waf_allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
enable_waf_logging = true
```

### Custom Domain Configuration

```hcl
enable_custom_domain = true
custom_domain_name   = "web.example.com"
route53_zone_name    = "example.com"
```

**Note**: Custom domain requires:

- `enable_cloudfront = true`
- Valid Route53 hosted zone
- DNS validation for ACM certificate (automatic)

### ECS Configuration

ECS configuration is handled through the ECS module. See `modules/ecs/README.md` for details.

## Inputs

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->

## Outputs

After deployment, key outputs include:

### Network

- `vpc_id` - VPC ID
- `public_subnet_ids` - Public subnet IDs
- `private_subnet_ids` - Private subnet IDs

### ALB

- `api_alb_url` - Direct API ALB URL
- `web_alb_url` - Direct Web ALB URL
- `api_alb_arn` - API ALB ARN
- `web_alb_arn` - Web ALB ARN

### CloudFront

- `cloudfront_url` - CloudFront HTTPS URL
- `cloudfront_api_url` - CloudFront API endpoint URL
- `custom_domain_url` - Custom domain URL (if enabled)
- `custom_domain_api_url` - Custom domain API URL (if enabled)

### WAF

- `waf_web_acl_id` - WAF Web ACL ID
- `waf_web_acl_arn` - WAF Web ACL ARN

### ECS

- `ecs_cluster_id` - ECS cluster ID
- `api_service_name` - API service name
- `web_service_name` - Web service name

View all outputs:

```bash
terraform output
```

## Examples

The `examples/` directory contains ready-to-use examples demonstrating different configurations:

### Basic Examples

- **[`vpc`](examples/vpc/)** - VPC-only setup with subnets, NAT gateways, and flow logs
- **[`alb`](examples/alb/)** - VPC + ALB with EC2 instances running Amazon Linux 2023 (HTTP)
- **[`alb-https`](examples/alb-https/)** - VPC + ALB with HTTPS, ACM certificate, and Route53 (custom domain)
- **[`ecs`](examples/ecs/)** - VPC + ALB + ECS Fargate services (Web and API) without CloudFront

### CloudFront Examples

- **[`cloudfront`](examples/cloudfront/)** - Full stack (VPC + ALB + ECS + CloudFront) without custom domain
- **[`cloudfront-custom-domain`](examples/cloudfront-custom-domain/)** - Full stack with custom domain, ACM certificate, and Route53 DNS
- **[`cloudfront-waf`](examples/cloudfront-waf/)** - Full stack with custom domain, WAF protection, and WAF logging to S3

Each example includes:

- Complete `main.tf` configuration
- Example `variables.tf` and `terraform.tfvars`
- Detailed `README.md` with usage instructions

**Quick Start with Examples:**

```bash
# Navigate to an example
cd examples/cloudfront

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Example Walkthrough

This example demonstrates deploying the full stack with CloudFront, ALB, and ECS.

### Step 1: Configure Variables

Create `terraform.tfvars`:

```hcl
name_prefix = "my-app"
aws_region  = "ap-southeast-2"

# Enable all modules
enable_alb        = true
enable_ecs        = true
enable_cloudfront = true

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-2a", "ap-southeast-2b"]
nat_gateway_per_az = false  # Single NAT Gateway for cost savings

# CloudFront Configuration
price_class                  = "PriceClass_200"
enable_cloudfront_access_logs = true
enable_waf_logging            = true
waf_rate_limit               = 2000

# Optional: Custom Domain
enable_custom_domain = false
# custom_domain_name   = "web.example.com"
# route53_zone_name    = "example.com"
```

### Step 2: Initialize and Plan

```bash
terraform init
terraform plan
```

### Step 3: Apply

```bash
terraform apply
```

This creates:

- VPC with public/private subnets and NAT gateway
- Two ALBs (web and API) with target groups
- ECS cluster with web and API services
- CloudFront distribution with WAF
- S3 buckets for static assets and logs

### Step 4: Access Your Application

After deployment completes:

```bash
# Get CloudFront URL
terraform output cloudfront_url

# Get direct ALB URLs
terraform output web_alb_url
terraform output api_alb_url
```

### Step 5: Verify Deployment

- CloudFront URL should serve your web application
- API endpoints available at `{cloudfront_url}/api`
- Check ECS services are running: `aws ecs list-services --cluster {cluster_name}`
- View logs: CloudWatch Logs groups for ECS tasks

## Cost Optimization

1. **NAT Gateways**: Set `nat_gateway_per_az = false` for single NAT Gateway (saves ~$32/month per additional NAT)
2. **CloudFront Price Class**: Use `PriceClass_200` or `PriceClass_100` to reduce data transfer costs
3. **Log Retention**: Reduce `flow_log_retention_days` and `log_retention_days` to minimize CloudWatch costs
4. **Logging**: Disable `enable_waf_logging` and `enable_cloudfront_access_logs` if not needed
5. **S3 Lifecycle**: Access logs automatically transition to cheaper storage classes and expire after 90 days

## Module Documentation

For detailed module documentation, see:

- [VPC Module](modules/vpc/README.md) - VPC, subnets, NAT gateways
- [ALB Module](modules/alb/README.md) - Load balancers, target groups, listeners
- [ECS Module](modules/ecs/README.md) - ECS cluster, services, task definitions
- [CloudFront Module](modules/cloudfront/README.md) - CDN, WAF, S3 origins
- [S3 Module](modules/s3/README.md) - Reusable S3 bucket module

## Validation Rules

The stack enforces dependency validation:

- `enable_ecs` requires `enable_alb = true`
- `enable_cloudfront` requires `enable_alb = true`
- `enable_custom_domain` requires `enable_cloudfront = true`
- `enable_alb` requires VPC (always created)

These validations prevent misconfiguration and ensure proper resource dependencies.

## Security Considerations

- **Security Groups**: Restrict access to only necessary ports and sources
- **WAF**: Rate limiting and method restrictions protect against common attacks
- **HTTPS**: Use ACM certificates for encrypted traffic
- **Private Subnets**: ECS tasks run in private subnets without public IPs
- **IAM Roles**: Least-privilege IAM roles for ECS tasks
- **S3 Bucket Policies**: Properly configured for CloudFront and ALB logging

## Troubleshooting

### CloudFront Distribution Not Updating

- CloudFront distributions can take 15-20 minutes to deploy
- Use `terraform apply -refresh=false` to avoid waiting for distribution updates

### Certificate Validation Failing

- Ensure Route53 hosted zone exists and is accessible
- Check DNS validation records are created correctly
- Wait for ACM validation (can take several minutes)

### ECS Tasks Not Starting

- Verify ALB target groups are healthy
- Check ECS task logs in CloudWatch
- Ensure security groups allow traffic between ALB and ECS tasks
