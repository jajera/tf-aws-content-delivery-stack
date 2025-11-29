# ALB S3 Logs Submodule

This submodule creates an S3 bucket specifically configured for storing ALB (Application Load Balancer) access logs.

## Features

- S3 bucket with automatic naming (`{prefix}-alb-logs-{suffix}`)
- Bucket policy allowing ELB service account to write logs
- Lifecycle rules for cost optimization:
  - Transitions to STANDARD_IA after 30 days
  - Transitions to GLACIER after 60 days
  - Auto-deletes after 90 days
- Server-side encryption (AES256)
- Public access blocked

## Usage

```hcl
module "alb_logs_s3" {
  source = "./modules/alb/s3-logs"

  name_prefix  = "my-app"
  name_suffix  = "abc123"
  aws_region   = "ap-southeast-2"
  force_destroy = false
  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for bucket name | string | - | yes |
| name_suffix | Suffix for bucket name | string | - | yes |
| aws_region | AWS region for ELB service account | string | - | yes |
| force_destroy | Allow deletion of non-empty bucket | bool | `false` | no |
| tags | Tags to apply to all resources | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | ID of the S3 bucket for ALB logs |
| bucket_arn | ARN of the S3 bucket for ALB logs |
| bucket_name | Name of the S3 bucket for ALB logs |

## Cost Considerations

The bucket includes lifecycle rules to minimize storage costs:

- Logs transition to cheaper storage classes automatically
- Old logs are automatically deleted after 90 days
- This helps prevent unbounded log storage costs
