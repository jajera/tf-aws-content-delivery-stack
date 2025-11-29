# S3 Module

This module creates a single S3 bucket with security best practices.

## Features

- S3 bucket with configurable name
- Public access block (all public access blocked)
- Optional versioning
- Server-side encryption (AES256)
- Optional bucket policy
- Configurable object ownership (for ACL support)
- Optional ACL grants (for CloudFront access logs, etc.)
- Optional lifecycle rules for cost optimization

## Usage

### Basic Usage

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name      = "my-app-assets"
  enable_versioning = false
  force_destroy     = false

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### With Bucket Policy

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name         = "my-app-assets"
  enable_bucket_policy = true
  bucket_policy_json   = data.aws_iam_policy_document.bucket_policy.json

  tags = {
    Environment = "production"
  }
}
```

### With ACLs (for CloudFront Access Logs)

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name      = "cloudfront-access-logs"
  object_ownership = "BucketOwnerPreferred" # Required for ACLs
  force_destroy    = true

  # ACL grants for CloudFront awslogsdelivery account
  acl_grants = [
    {
      id         = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

### With Lifecycle Rules

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name = "my-app-logs"

  lifecycle_rules = [
    {
      id              = "delete-old-logs"
      status          = "Enabled"
      expiration_days = 90
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | - | yes |
| enable_versioning | Enable S3 bucket versioning | bool | `false` | no |
| force_destroy | Allow deletion of non-empty bucket | bool | `false` | no |
| tags | Tags to apply to all resources | map(string) | `{}` | no |
| bucket_policy_json | JSON policy document to attach to the bucket. If not provided, no policy will be attached. | string | `null` | no |
| enable_bucket_policy | Whether to create a bucket policy. Set to true if bucket_policy_json is provided (even if unknown at plan time). | bool | `false` | no |
| object_ownership | Object ownership setting for the bucket. Set to 'BucketOwnerPreferred' to enable ACLs, 'BucketOwnerEnforced' to disable ACLs (default). | string | `"BucketOwnerEnforced"` | no |
| acl_grants | List of ACL grants. Each grant should have 'id' (canonical user ID), 'type' ('CanonicalUser'), and 'permission' ('READ', 'WRITE', 'READ_ACP', 'WRITE_ACP', 'FULL_CONTROL'). Only used if object_ownership is 'BucketOwnerPreferred'. | list(object) | `[]` | no |
| lifecycle_rules | List of lifecycle rules for the bucket. Each rule should have 'id', 'status' ('Enabled' or 'Disabled'), optional 'expiration_days', and optional 'transitions' list with 'days' and 'storage_class'. | list(object) | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | ID of the S3 bucket |
| bucket_arn | ARN of the S3 bucket |
| bucket_name | Name of the S3 bucket |
| bucket_domain_name | Domain name of the S3 bucket |
| bucket_regional_domain_name | Regional domain name of the S3 bucket |
