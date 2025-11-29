# ECS Example

This example demonstrates deploying a VPC with Application Load Balancers (ALB) and ECS Fargate services running containerized applications.

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
- S3 bucket for ALB access logs (optional)

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS Provider** >= 6.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create VPC, ECS, ALB, IAM, S3, and CloudWatch resources

## Usage

1. **Review configuration**

   Edit `main.tf` to customize values (VPC CIDR, availability zones, etc.).

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

5. **View outputs**

   ```bash
   terraform output
   ```

6. **Access the demo application**

   Use the `web_alb_url` and `api_alb_url` outputs to access the demo applications.

## Configuration

Key settings in `main.tf`:

- `nat_gateway_per_az = false` - Cost effective (single NAT Gateway). Set to `true` for resiliency (NAT per AZ).
- `force_destroy = true` - Allows deletion of resources with data (e.g., S3 buckets with logs, CloudWatch Log Groups).
- `flow_log_retention_days = 7` - CloudWatch Logs retention period.
- `enable_alb = true` - Creates ALBs (required for ECS).
- `enable_ecs = true` - Creates ECS cluster and services.
- `enable_cloudfront = false` - CloudFront is disabled in this example.

### Optional: Container Insights

To enable CloudWatch Container Insights for the ECS cluster:

```hcl
enable_container_insights = true
```

### Optional: S3 Access Logs

The S3 bucket for ALB access logs is created automatically when ALB is enabled. This is optional but recommended for production.

## Outputs

After deployment, the following outputs are available:

- `web_alb_url` - HTTP URL of the Web ALB - use this URL to access the web application
- `api_alb_url` - HTTP URL of the API ALB - use this URL to access the API

View outputs with: `terraform output`

## Demo Application

The ECS services run containerized applications:

### Web Service

- Container image: `ghcr.io/platformfuzz/geomag-web-image:latest`
- Port: `80`
- Environment variable: `API_BASE_URL` (points to API ALB)
- Health check: `curl`-based health check

### API Service

- Container image: `ghcr.io/platformfuzz/geomag-api-image:latest`
- Port: `8000`
- Health check: Python-based HTTP health check on `/health` endpoint

Both services:

- Run on Fargate (serverless containers)
- Scale to one task per availability zone
- Use CloudWatch Logs for container logs (separate log group per service)
- Are accessible through their respective ALBs

**Note:** This example uses the root module which creates a complete stack (VPC + ALB + ECS). The ECS module internally uses reusable submodules (cluster and service) that can be used independently if needed.

## Cost Considerations

- **NAT Gateway**: ~$32/month per NAT Gateway + data transfer costs
- **ALB**: ~$16/month per ALB (2 ALBs = ~$32/month) + LCU charges
- **ECS Fargate**: ~$0.04/vCPU-hour and ~$0.004/GB-hour (2 services × 2 tasks = ~$15-20/month for t3.micro equivalent)
- **VPC Flow Logs**: CloudWatch Logs ingestion and storage costs
- **ALB Access Logs**: S3 storage costs (lifecycle policy transitions to cheaper storage)
- **CloudWatch Logs**: Log ingestion and storage costs (per service log groups)

Set `nat_gateway_per_az = false` to use a single NAT Gateway and reduce costs.

## Next Steps

Once VPC, ALB, and ECS services are created, you can:

- Add CloudFront: Set `enable_cloudfront = true` in the root module (requires ALB)
- Customize containers: Update container images in the ECS module
- Scale services: Adjust `desired_count` in the ECS service submodules
