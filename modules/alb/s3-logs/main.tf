# Data source to get ELB service account ID for the region
data "aws_elb_service_account" "this" {}

# S3 Bucket Policy document for ALB access logs
# ELB service account needs permission to write logs to the bucket
locals {
  bucket_name = "${var.name_prefix}-alb-logs-${var.name_suffix}"
}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    sid    = "AllowELBToWriteLogs"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }

  statement {
    sid    = "AllowELBToCheckBucket"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}"
    ]
  }
}

# ALB access logs bucket using reusable S3 module
module "s3" {
  source = "../../s3"

  bucket_name   = local.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags

  # Bucket policy for ELB service account to write logs
  enable_bucket_policy = true
  bucket_policy_json   = data.aws_iam_policy_document.alb_logs.json

  # Lifecycle policy - auto-delete after 90 days, transition to cheaper storage
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
}
