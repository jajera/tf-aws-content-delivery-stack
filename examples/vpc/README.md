# VPC Only Example

This example demonstrates deploying a VPC only infrastructure.

## What Gets Created

- VPC with configurable CIDR
- Public subnets (for NAT Gateway placement)
- Private subnets (for future ECS tasks)
- Internet Gateway
- NAT Gateway(s) for outbound internet access
- Route tables and associations
- VPC Flow Logs to CloudWatch Logs

## Prerequisites

- **Terraform** >= 1.5.0
- **AWS Provider** >= 6.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create VPC, EC2, and CloudWatch resources

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

## Configuration

Key settings in `main.tf`:

- `nat_gateway_per_az = false` - Cost effective (single NAT Gateway). Set to `true` for resiliency (NAT per AZ).
- `force_destroy = true` - Allows deletion of resources with data (e.g., S3 buckets with logs).
- `flow_log_retention_days = 7` - CloudWatch Logs retention period.

### Network Flow Example

**Outbound from Private Subnet:**

1. Resource in private subnet makes request
2. Route table routes traffic to NAT Gateway
3. NAT Gateway (in public subnet) forwards to Internet Gateway
4. Internet Gateway sends to internet

**Inbound to Public Subnet:**

1. Internet traffic arrives at Internet Gateway
2. Route table routes to public subnet resource
3. Resource receives traffic directly

**Private to Private:**

1. Traffic stays within VPC
2. Routed via VPC's internal routing (no NAT Gateway needed)

## Outputs

After deployment, the following outputs are available:

- `vpc_id` - ID of the created VPC
- `vpc_cidr` - CIDR block of the VPC
- `public_subnet_ids` - IDs of the public subnets
- `private_subnet_ids` - IDs of the private subnets

View outputs with: `terraform output`

## Cost Considerations

- **NAT Gateway**: ~$32/month per NAT Gateway + data transfer costs
- **VPC Flow Logs**: CloudWatch Logs ingestion and storage costs
- Set `nat_gateway_per_az = false` to use a single NAT Gateway and reduce costs

## Next Steps

Once VPC is created, you can:

- Enable ALB: Set `enable_alb = true` in the root module
- Deploy ECS services: Set `enable_ecs = true` (requires ALB)
- Add CloudFront: Set `enable_cloudfront = true` (requires ALB)
