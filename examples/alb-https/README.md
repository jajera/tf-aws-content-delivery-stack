# ALB HTTPS Example

This example demonstrates deploying a VPC with an Application Load Balancer (ALB) configured with HTTPS and EC2 instances running a demo web application.

## What Gets Created

- VPC with configurable CIDR
- Public subnets (for NAT Gateway and ALB placement)
- Private subnets (for EC2 instances)
- Internet Gateway
- NAT Gateway(s) for outbound internet access
- Route tables and associations
- VPC Flow Logs to CloudWatch Logs
- Application Load Balancer (Web ALB) with HTTPS enabled
- Target group for Web (port 80)
- HTTPS listener on port 443
- HTTP listener on port 80 (redirects to HTTPS)
- Security groups allowing HTTP/HTTPS from internet
- ACM Certificate for HTTPS (optional - can use existing certificate)
- EC2 instances (Amazon Linux 2023) running Apache httpd web server
- S3 bucket for ALB access logs (optional)

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS Provider** >= 6.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create VPC, EC2, ALB, ACM, S3, and CloudWatch resources
- **Domain name** (optional - if creating new ACM certificate) or existing ACM certificate ARN

## Usage

1. **Configure certificate**

   You have two options:

   **Option A: Use existing certificate ARN**

   ```bash
   terraform apply -var="alb_certificate_arn=arn:aws:acm:ap-southeast-2:123456789012:certificate/abc123..."
   ```

   **Option B: Create new certificate (requires domain name)**

   ```bash
   terraform apply -var="domain_name=example.com"
   ```

   Note: You'll need to validate the certificate via DNS or email.

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

   Use the `alb_url` output (HTTPS) to access the demo web application. HTTP requests will automatically redirect to HTTPS.

## Configuration

Key settings in `main.tf`:

- `domain_name` - Domain name for ACM certificate (optional, if creating new certificate)
- `alb_certificate_arn` - ARN of existing ACM certificate (optional, if using existing certificate)
- `nat_gateway_per_az = false` - Cost effective (single NAT Gateway). Set to `true` for resiliency (NAT per AZ).
- `force_destroy = true` - Allows deletion of resources with data (e.g., S3 buckets with logs).
- `flow_log_retention_days = 7` - CloudWatch Logs retention period.
- `user_data_replace_on_change = true` - Forces EC2 instance replacement when user_data changes.

### Certificate Options

#### Option 1: Use existing certificate ARN

```hcl
variable "alb_certificate_arn" {
  default = "arn:aws:acm:ap-southeast-2:123456789012:certificate/abc123..."
}
```

#### Option 2: Create new certificate

```hcl
variable "domain_name" {
  default = "example.com"
}
```

Note: If creating a new certificate, you'll need to complete DNS validation. The certificate will be created but validation must be completed manually or via Route53.

### Optional: S3 Access Logs

The S3 bucket for ALB access logs is optional. You can remove the `alb_logs_s3` module and set `access_logs_bucket_id = null` in the ALB module (if the module supports it), or comment out the access_logs configuration.

## Outputs

After deployment, the following outputs are available:

- `alb_url` - HTTPS URL of the Web ALB - use this URL to access the demo application (HTTP requests will be redirected to HTTPS)
- `alb_dns_name` - DNS name of the Web ALB
- `certificate_arn` - ARN of the ACM certificate used for HTTPS

View outputs with: `terraform output`

## Demo Application

The EC2 instances run a simple web server that displays:

- A welcome message
- Instance ID (fetched using IMDSv2)
- Availability Zone

This demonstrates load balancing across multiple instances in different availability zones.

**Note:** EC2 instances were chosen as a simple way to serve a web application for this demo. This provides a middle ground between a static fixed response (which doesn't demonstrate real load balancing) and a full-blown ECS setup (which adds complexity). EC2 instances allow you to see actual load balancing behavior across multiple backend instances.

## HTTPS Configuration

This example demonstrates:

- **HTTPS listener** on port 443 with TLS termination at the ALB
- **HTTP to HTTPS redirect** - All HTTP traffic is automatically redirected to HTTPS
- **ACM certificate** - Uses AWS Certificate Manager for SSL/TLS certificates
- **End-to-end security** - Traffic from internet to ALB is encrypted, ALB to EC2 is HTTP (internal network)

## Cost Considerations

- **NAT Gateway**: ~$32/month per NAT Gateway + data transfer costs
- **ALB**: ~$16/month per ALB + LCU charges
- **EC2 Instances**: ~$7.50/month per t3.micro instance (2 instances = ~$15/month)
- **ACM Certificate**: Free (AWS managed certificates)
- **VPC Flow Logs**: CloudWatch Logs ingestion and storage costs
- **ALB Access Logs**: S3 storage costs (lifecycle policy transitions to cheaper storage)

Set `nat_gateway_per_az = false` to use a single NAT Gateway and reduce costs.

## Next Steps

Once VPC, ALB with HTTPS, and EC2 instances are created, you can:

- Deploy ECS services: Set `enable_ecs = true` in the root module (requires ALB)
- Add CloudFront: Set `enable_cloudfront = true` in the root module (requires ALB)
