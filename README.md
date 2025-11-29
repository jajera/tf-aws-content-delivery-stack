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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_api"></a> [alb\_api](#module\_alb\_api) | ./modules/alb | n/a |
| <a name="module_alb_logs_s3"></a> [alb\_logs\_s3](#module\_alb\_logs\_s3) | ./modules/alb/s3-logs | n/a |
| <a name="module_alb_web"></a> [alb\_web](#module\_alb\_web) | ./modules/alb | n/a |
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | ./modules/cloudfront | n/a |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | ./modules/ecs | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_certificate_arn"></a> [alb\_certificate\_arn](#input\_alb\_certificate\_arn) | ARN of ACM certificate for ALB HTTPS listener (optional) | `string` | `null` | no |
| <a name="input_alb_origin_protocol_policy"></a> [alb\_origin\_protocol\_policy](#input\_alb\_origin\_protocol\_policy) | Protocol policy for ALB origin | `string` | `"https-only"` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones | `list(string)` | <pre>[<br/>  "ap-southeast-2a",<br/>  "ap-southeast-2b"<br/>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"ap-southeast-2"` | no |
| <a name="input_custom_domain_name"></a> [custom\_domain\_name](#input\_custom\_domain\_name) | Custom domain name for CloudFront (e.g., web.example.com). Required if enable\_custom\_domain is true | `string` | `null` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Default root object for CloudFront | `string` | `"index.html"` | no |
| <a name="input_enable_alb"></a> [enable\_alb](#input\_enable\_alb) | If true, creates Application Load Balancer (ALB) for routing traffic to ECS services | `bool` | `false` | no |
| <a name="input_enable_cloudfront"></a> [enable\_cloudfront](#input\_enable\_cloudfront) | If true, creates CloudFront distribution and web container will use CloudFront URL for API calls (enables caching). If false, CloudFront is not created and uses ALB directly. Requires ALB to be enabled | `bool` | `false` | no |
| <a name="input_enable_cloudfront_access_logs"></a> [enable\_cloudfront\_access\_logs](#input\_enable\_cloudfront\_access\_logs) | Enable CloudFront access logs to S3 | `bool` | `false` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Enable CloudWatch Container Insights | `bool` | `false` | no |
| <a name="input_enable_custom_domain"></a> [enable\_custom\_domain](#input\_enable\_custom\_domain) | If true, enables custom domain for CloudFront with ACM certificate and Route53 DNS records | `bool` | `false` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection for ALB | `bool` | `false` | no |
| <a name="input_enable_ecs"></a> [enable\_ecs](#input\_enable\_ecs) | If true, creates ECS cluster and services. Requires ALB to be enabled | `bool` | `false` | no |
| <a name="input_enable_https"></a> [enable\_https](#input\_enable\_https) | If true and certificate is provided, redirect HTTP to HTTPS. If false or no certificate, HTTP listener will forward to target group. | `bool` | `false` | no |
| <a name="input_enable_s3_versioning"></a> [enable\_s3\_versioning](#input\_enable\_s3\_versioning) | Enable S3 bucket versioning | `bool` | `false` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable WAF Web ACL for CloudFront distribution | `bool` | `false` | no |
| <a name="input_enable_waf_logging"></a> [enable\_waf\_logging](#input\_enable\_waf\_logging) | Enable WAF logging to Kinesis Firehose. Requires enable\_waf to be true | `bool` | `false` | no |
| <a name="input_flow_log_retention_days"></a> [flow\_log\_retention\_days](#input\_flow\_log\_retention\_days) | Number of days to retain VPC Flow Logs | `number` | `7` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | If true, Terraform will not prevent destruction of resources | `bool` | `false` | no |
| <a name="input_geo_restriction_locations"></a> [geo\_restriction\_locations](#input\_geo\_restriction\_locations) | List of country codes for geo restriction | `list(string)` | `[]` | no |
| <a name="input_geo_restriction_type"></a> [geo\_restriction\_type](#input\_geo\_restriction\_type) | Geo restriction type | `string` | `"none"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs | `number` | `7` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all resource names | `string` | n/a | yes |
| <a name="input_nat_gateway_per_az"></a> [nat\_gateway\_per\_az](#input\_nat\_gateway\_per\_az) | If true, create one NAT Gateway per availability zone (high availability). If false, create a single NAT Gateway (cost savings) | `bool` | `false` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | CloudFront price class | `string` | `"PriceClass_All"` | no |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | Route53 hosted zone name (e.g., example.com). Required if enable\_custom\_domain is true | `string` | `null` | no |
| <a name="input_subnet_bits"></a> [subnet\_bits](#input\_subnet\_bits) | Number of bits to add to VPC CIDR for subnet calculation | `number` | `8` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | <pre>{<br/>  "ManagedBy": "Terraform"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_waf_allowed_methods"></a> [waf\_allowed\_methods](#input\_waf\_allowed\_methods) | List of allowed HTTP methods for WAF. Requests with other methods will be blocked | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS",<br/>  "POST",<br/>  "PUT",<br/>  "PATCH",<br/>  "DELETE"<br/>]</pre> | no |
| <a name="input_waf_rate_limit"></a> [waf\_rate\_limit](#input\_waf\_rate\_limit) | WAF rate limit per 5-minute period per IP address. Set to 0 to disable rate limiting | `number` | `2000` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_alb_arn"></a> [api\_alb\_arn](#output\_api\_alb\_arn) | ARN of the API ALB |
| <a name="output_api_alb_dns_name"></a> [api\_alb\_dns\_name](#output\_api\_alb\_dns\_name) | DNS name of the API ALB |
| <a name="output_api_alb_url"></a> [api\_alb\_url](#output\_api\_alb\_url) | HTTP URL that hits the API ALB directly |
| <a name="output_api_listener_arns"></a> [api\_listener\_arns](#output\_api\_listener\_arns) | ARNs of API ALB listeners |
| <a name="output_api_service_name"></a> [api\_service\_name](#output\_api\_service\_name) | Name of the API ECS service |
| <a name="output_api_target_group_arn"></a> [api\_target\_group\_arn](#output\_api\_target\_group\_arn) | Target group ARN for the API service |
| <a name="output_cloudfront_api_url"></a> [cloudfront\_api\_url](#output\_cloudfront\_api\_url) | HTTPS URL for API endpoints served via CloudFront |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | ID of the CloudFront distribution |
| <a name="output_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#output\_cloudfront\_domain\_name) | Domain name assigned by CloudFront |
| <a name="output_cloudfront_url"></a> [cloudfront\_url](#output\_cloudfront\_url) | HTTPS URL served via CloudFront |
| <a name="output_custom_domain_api_url"></a> [custom\_domain\_api\_url](#output\_custom\_domain\_api\_url) | HTTPS URL for API endpoints via custom domain (if enabled) |
| <a name="output_custom_domain_url"></a> [custom\_domain\_url](#output\_custom\_domain\_url) | HTTPS URL for the custom domain (if enabled) |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ID of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private subnets used by ECS |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets (for ALBs/NAT) |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | CIDR block assigned to the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the provisioned VPC |
| <a name="output_waf_web_acl_arn"></a> [waf\_web\_acl\_arn](#output\_waf\_web\_acl\_arn) | ARN of the WAF Web ACL protecting CloudFront |
| <a name="output_waf_web_acl_id"></a> [waf\_web\_acl\_id](#output\_waf\_web\_acl\_id) | ID of the WAF Web ACL protecting CloudFront |
| <a name="output_web_alb_arn"></a> [web\_alb\_arn](#output\_web\_alb\_arn) | ARN of the Web ALB |
| <a name="output_web_alb_dns_name"></a> [web\_alb\_dns\_name](#output\_web\_alb\_dns\_name) | DNS name of the Web ALB |
| <a name="output_web_alb_url"></a> [web\_alb\_url](#output\_web\_alb\_url) | HTTP URL that hits the Web ALB directly |
| <a name="output_web_assets_bucket_domain_name"></a> [web\_assets\_bucket\_domain\_name](#output\_web\_assets\_bucket\_domain\_name) | Regional domain name for the static asset bucket |
| <a name="output_web_assets_bucket_name"></a> [web\_assets\_bucket\_name](#output\_web\_assets\_bucket\_name) | Name of the S3 bucket that stores static web assets |
| <a name="output_web_listener_arns"></a> [web\_listener\_arns](#output\_web\_listener\_arns) | ARNs of Web ALB listeners |
| <a name="output_web_service_name"></a> [web\_service\_name](#output\_web\_service\_name) | Name of the Web ECS service |
| <a name="output_web_target_group_arn"></a> [web\_target\_group\_arn](#output\_web\_target\_group\_arn) | Target group ARN for the Web service |
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
