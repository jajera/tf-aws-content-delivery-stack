# CloudFront Custom Domain Example

This example demonstrates deploying a complete content delivery stack with VPC, Application Load Balancers (ALB), ECS Fargate services, CloudFront distribution, and a custom domain with ACM certificate and Route53 DNS.

## What Gets Created

- VPC with configurable CIDR
- Public subnets (for NAT Gateway and ALB placement)
- Private subnets (for ECS tasks)
- Internet Gateway
- NAT Gateway(s) for outbound internet access
- Route tables and associations
- VPC Flow Logs to CloudWatch Logs
- Two Application Load Balancers (Web ALB and API ALB)
- Target groups for Web (port 80) and API (port 8000)
- HTTP listeners on ports 80 and 8000
- Security groups allowing HTTP from internet
- ECS Fargate cluster
- Two ECS Fargate services (Web and API) with task definitions
- CloudWatch log groups for ECS tasks (per service)
- IAM roles for ECS task execution and task roles
- S3 bucket for ALB access logs
- **CloudFront distribution** with:
  - Web ALB as default origin (dynamic content)
  - API ALB as origin for `/api/*` routes
  - S3 bucket for static assets and error pages
  - Custom error responses (403, 404, 500, etc.)
  - HTTPS by default with custom domain certificate
  - **Optional WAF** (disabled by default)
- S3 bucket for static web assets (with CloudFront Origin Access Control)
- **ACM Certificate** (wildcard certificate in `us-east-1` for CloudFront)
- **Route53 DNS records** (A records pointing custom domain to CloudFront)

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS Provider** >= 6.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create VPC, ECS, ALB, IAM, S3, CloudWatch, CloudFront, ACM, Route53, and WAF resources
- **Route53 Hosted Zone** for your domain (must exist before deployment)
- **Domain name** for CloudFront (e.g., `web.example.com`)

## Usage

1. **Configure domain variables**

   Edit `terraform.tfvars` or set variables:

   ```hcl
   custom_domain_name = "web.example.com"
   route53_zone_name  = "example.com"
   ```

   **Important:** The Route53 hosted zone must already exist in your AWS account.

2. **Initialize Terraform**

   ```bash
   terraform init
   ```

3. **Plan deployment**

   ```bash
   terraform plan
   ```

4. **Apply configuration**

   ```bash
   terraform apply
   ```

   **Note:** ACM certificate validation may take a few minutes. The certificate will be automatically validated via Route53 DNS records.

5. **View outputs**

   ```bash
   terraform output
   ```

6. **Access the demo application**

   Use the `custom_domain_url` output to access the web application via your custom domain (HTTPS). Use `custom_domain_api_url` for API endpoints.

## Configuration

Key settings in `main.tf`:

- `custom_domain_name` - Custom domain name for CloudFront (e.g., `web.example.com`)
- `route53_zone_name` - Route53 hosted zone name (e.g., `example.com`)
- `nat_gateway_per_az = false` - Cost effective (single NAT Gateway). Set to `true` for resiliency (NAT per AZ).
- `force_destroy = true` - Allows deletion of resources with data (e.g., S3 buckets with logs, CloudWatch Log Groups).
- `flow_log_retention_days = 7` - CloudWatch Logs retention period.
- `enable_alb = true` - Creates ALBs (required for ECS and CloudFront).
- `enable_ecs = true` - Creates ECS cluster and services.
- `enable_cloudfront = true` - Creates CloudFront distribution.
- `enable_custom_domain = true` - Enables custom domain configuration.

### Domain Configuration

The example requires:

1. **Route53 Hosted Zone**: Must exist before deployment. Create it manually or via Terraform:

   ```hcl
   resource "aws_route53_zone" "example" {
     name = "example.com"
   }
   ```

2. **Custom Domain Name**: Subdomain for CloudFront (e.g., `web.example.com`)

3. **ACM Certificate**: Automatically created in `us-east-1` (required for CloudFront) and validated via Route53 DNS records.

### Optional: Enable WAF

WAF is **disabled by default** to reduce costs. To enable WAF protection:

```hcl
enable_waf = true
```

When enabled, WAF provides:

- Rate limiting (default: 2000 requests per 5-minute period per IP)
- HTTP method restrictions (blocks disallowed methods)
- Optional logging to Kinesis Firehose and S3

To enable WAF with logging:

```hcl
enable_waf           = true
enable_waf_logging   = true
waf_rate_limit       = 2000  # Requests per 5-minute period per IP (0 = disabled)
waf_allowed_methods  = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
```

### Optional: Container Insights

To enable CloudWatch Container Insights for the ECS cluster:

```hcl
enable_container_insights = true
```

## Outputs

After deployment, the following outputs are available:

- `custom_domain_url` - HTTPS URL for the custom domain - use this URL to access the web application
- `custom_domain_api_url` - HTTPS URL for API endpoints via custom domain - use this URL to access the API
- `cloudfront_url` - HTTPS URL served via CloudFront (default domain) - use this URL to access the web application
- `cloudfront_api_url` - HTTPS URL for API endpoints served via CloudFront (default domain) - use this URL to access the API

View outputs with: `terraform output`

**Note:** Always use the custom domain URLs (`custom_domain_url` and `custom_domain_api_url`) for production traffic. The default CloudFront URLs are provided for reference and debugging.

## Demo Application

The ECS services run containerized applications behind CloudFront with a custom domain:

### Web Service

- Container image: `ghcr.io/platformfuzz/geomag-web-image:latest`
- Port: `80`
- Environment variable: `API_BASE_URL` (points to CloudFront API URL)
- Health check: `curl`-based health check
- Served via CloudFront at root path `/`

### API Service

- Container image: `ghcr.io/platformfuzz/geomag-api-image:latest`
- Port: `8000`
- Health check: Python-based HTTP health check on `/health` endpoint
- Served via CloudFront at `/api/*` paths

Both services:

- Run on Fargate (serverless containers)
- Scale to one task per availability zone
- Use CloudWatch Logs for container logs (separate log group per service)
- Are accessible through CloudFront (HTTPS) with your custom domain or directly via ALBs (HTTP)

### CloudFront Configuration

- **Default cache behavior**: Routes to Web ALB with minimal caching (dynamic content)
- **API cache behavior**: Routes `/api/*` to API ALB with query-aware caching
- **Static assets**: Served from S3 with optimized caching
- **Error pages**: Custom error pages (403, 404, 500) served from S3
- **HTTPS**: All traffic is HTTPS (HTTP redirects to HTTPS)
- **Custom domain**: Uses ACM certificate and Route53 DNS for your domain
- **ACM Certificate**: Wildcard certificate created in `us-east-1` (CloudFront requirement)
- **Route53 Records**: A records (alias) pointing custom domain to CloudFront distribution

**Note:** This example uses the root module which creates a complete stack (VPC + ALB + ECS + CloudFront + Custom Domain). The modules internally use reusable submodules that can be used independently if needed.

## Certificate Validation

The ACM certificate is automatically validated via Route53 DNS records:

1. Certificate is created in `us-east-1` (required for CloudFront)
2. Route53 validation records are created automatically
3. Certificate validation completes automatically (usually within a few minutes)
4. CloudFront distribution uses the validated certificate

If validation fails, check:

- Route53 hosted zone exists and is accessible
- DNS records are created correctly
- Certificate is in `us-east-1` region (CloudFront requirement)

## Cost Considerations

- **NAT Gateway**: ~$32/month per NAT Gateway + data transfer costs
- **ALB**: ~$16/month per ALB (2 ALBs = ~$32/month) + LCU charges
- **ECS Fargate**: ~$0.04/vCPU-hour and ~$0.004/GB-hour (2 services × 2 tasks = ~$15-20/month for t3.micro equivalent)
- **CloudFront**: Data transfer out costs (varies by region and volume) + requests
- **ACM Certificate**: Free (AWS managed certificates)
- **Route53**: ~$0.50/month per hosted zone + $0.40 per million queries
- **WAF** (if enabled): ~$5/month per Web ACL + $1 per million requests
- **VPC Flow Logs**: CloudWatch Logs ingestion and storage costs
- **ALB Access Logs**: S3 storage costs (lifecycle policy transitions to cheaper storage)
- **CloudWatch Logs**: Log ingestion and storage costs (per service log groups)

Set `nat_gateway_per_az = false` to use a single NAT Gateway and reduce costs. Keep `enable_waf = false` (default) to avoid WAF costs.

## Next Steps

Once the stack is deployed, you can:

- **Enable WAF**: Set `enable_waf = true` for production workloads
- **Add additional domains**: Configure multiple custom domains (requires module modifications)
- **Customize containers**: Update container images in the ECS module
- **Scale services**: Adjust `desired_count` in the ECS service submodules
- **Configure caching**: Adjust CloudFront cache policies for better performance
- **Set up monitoring**: Add CloudWatch alarms and dashboards
