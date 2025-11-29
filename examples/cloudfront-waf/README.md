# CloudFront WAF Example

This example demonstrates deploying a complete content delivery stack with VPC, Application Load Balancers (ALB), ECS Fargate services, CloudFront distribution, **custom domain**, and **WAF protection with logging**.

Compared to the `cloudfront-custom-domain` example, this adds:

- WAF Web ACL attached to CloudFront
- Rate limiting rule (per IP)
- HTTP method restriction rule
- WAF logging to Kinesis Firehose and S3 (with sensitive fields redacted)

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
- S3 bucket for static web assets (with CloudFront Origin Access Control)
- **ACM Certificate** in `us-east-1` for the custom domain
- **Route53 DNS records** (A/AAAA alias records pointing custom domain to CloudFront)
- **WAF Web ACL** attached to CloudFront
  - Rate limit rule (per IP) using `waf_rate_limit`
  - HTTP method restriction rule using `waf_allowed_methods`
- **WAF logging pipeline**
  - Kinesis Firehose delivery stream for WAF logs
  - S3 bucket for WAF logs with lifecycle configuration
  - WAF logging configuration with sensitive fields redacted

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS Provider** >= 6.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create VPC, ECS, ALB, IAM, S3, CloudWatch, CloudFront, ACM, Route53, WAF, and Kinesis Firehose resources
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
- `enable_waf = true` - Enables WAF Web ACL for CloudFront.
- `enable_waf_logging = true` - Enables WAF logging pipeline (Firehose + S3).

### WAF Configuration

WAF is **enabled by default** in this example. The module supports:

- **Rate limiting** via `waf_rate_limit` (requests per 5-minute period per IP)
- **HTTP method restrictions** via `waf_allowed_methods`
- **Logging** to Kinesis Firehose and S3 when `enable_waf_logging = true`

Key WAF variables:

```hcl
waf_rate_limit      = 2000  # Requests per 5-minute period per IP (0 = disable rate limit)
waf_allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
```

Behavior:

- Requests exceeding `waf_rate_limit` are **blocked** by the `RateLimitRule`
- Requests using HTTP methods **not** in `waf_allowed_methods` are **blocked** by `MethodRestrictionRule`
- Method matching is **case-insensitive** (GET/get/Get all work)

### WAF Logging and Redaction

When `enable_waf_logging = true`, WAF logs are sent to Kinesis Firehose and stored in S3.

The logging configuration **redacts** sensitive fields to reduce cost and protect data:

- `query_string` (query parameters)
- `authorization` header
- `cookie` header

This keeps logs useful for security analysis while avoiding sensitive data exposure.

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

The ECS services run containerized applications behind CloudFront with a custom domain and WAF protection:

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
- **Route53 Records**: A/AAAA alias records pointing custom domain to CloudFront distribution
- **WAF Web ACL**: Attached to CloudFront for rate limiting and method restrictions

**Note:** This example uses the root module which creates a complete stack (VPC + ALB + ECS + CloudFront + Custom Domain + WAF). The modules internally use reusable submodules that can be used independently if needed.

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
- **WAF**: ~$5/month per Web ACL + $1 per million requests
- **Kinesis Firehose** (for WAF logs): Ingestion + S3 storage costs
- **VPC Flow Logs**: CloudWatch Logs ingestion and storage costs
- **ALB Access Logs**: S3 storage costs (lifecycle policy transitions to cheaper storage)
- **CloudWatch Logs**: Log ingestion and storage costs (per service log groups)

Set `nat_gateway_per_az = false` to use a single NAT Gateway and reduce costs. Tune `waf_rate_limit` and `waf_allowed_methods` based on your traffic patterns.

## Next Steps

Once the stack is deployed, you can:

- **Tune WAF rules**: Adjust `waf_rate_limit` and `waf_allowed_methods` for your application
- **Analyze WAF logs**: Use Athena or other tools to query WAF logs in S3
- **Add additional domains**: Configure multiple custom domains (requires module modifications)
- **Customize containers**: Update container images in the ECS module
- **Scale services**: Adjust `desired_count` in the ECS service submodules
- **Configure caching**: Adjust CloudFront cache policies for better performance
- **Set up monitoring**: Add CloudWatch alarms and dashboards for WAF, ALB, ECS, and CloudFront
