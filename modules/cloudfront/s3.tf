module "s3-web-assets" {
  source = "../s3"

  bucket_name   = "${var.name_prefix}-web-assets-${var.name_suffix}"
  force_destroy = var.force_destroy
  tags          = var.tags
}

# S3 Bucket Policy document for CloudFront access logs
# CloudFront service needs permission to write logs to the bucket
# Note: We construct the ARN pattern since we know the bucket name
locals {
  cloudfront_access_logs_bucket_name = "${var.name_prefix}-cloudfront-access-logs-${var.name_suffix}"
}

data "aws_iam_policy_document" "cloudfront_access_logs" {
  count = var.enable_cloudfront_access_logs ? 1 : 0

  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.cloudfront_access_logs_bucket_name}/*"]

    # Condition to restrict access to this specific CloudFront distribution
    # Note: Distribution ARN will be available when this is evaluated
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

# CloudFront access logs bucket using reusable S3 module
module "s3-cloudfront-access-logs" {
  source = "../s3"
  count  = var.enable_cloudfront_access_logs ? 1 : 0

  bucket_name      = local.cloudfront_access_logs_bucket_name
  force_destroy    = var.force_destroy
  object_ownership = "BucketOwnerPreferred" # Required for CloudFront access logs ACLs
  tags             = var.tags

  # ACL grants for CloudFront awslogsdelivery account (required for access logs)
  acl_grants = [
    {
      id         = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      type       = "CanonicalUser"
      permission = "FULL_CONTROL"
    }
  ]

  # Bucket policy for CloudFront service to write logs
  enable_bucket_policy = true
  bucket_policy_json   = data.aws_iam_policy_document.cloudfront_access_logs[0].json

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

# Managed custom error page object in the web-assets bucket
resource "aws_s3_object" "custom_403_page" {
  bucket       = module.s3-web-assets.bucket_id
  key          = "403.html"
  source       = "${path.module}/pages/403.html"
  content_type = "text/html; charset=UTF-8"
  etag         = filemd5("${path.module}/pages/403.html")
}

resource "aws_s3_object" "custom_404_page" {
  bucket       = module.s3-web-assets.bucket_id
  key          = "404.html"
  source       = "${path.module}/pages/404.html"
  content_type = "text/html; charset=UTF-8"
  etag         = filemd5("${path.module}/pages/404.html")
}

resource "aws_s3_object" "custom_500_page" {
  bucket       = module.s3-web-assets.bucket_id
  key          = "500.html"
  source       = "${path.module}/pages/500.html"
  content_type = "text/html; charset=UTF-8"
  etag         = filemd5("${path.module}/pages/500.html")
}

resource "aws_s3_object" "custom_405_page" {
  bucket       = module.s3-web-assets.bucket_id
  key          = "405.html"
  source       = "${path.module}/pages/405.html"
  content_type = "text/html; charset=UTF-8"
  etag         = filemd5("${path.module}/pages/405.html")
}

resource "aws_s3_object" "api_landing_page" {
  bucket       = module.s3-web-assets.bucket_id
  key          = "api.html"
  source       = "${path.module}/pages/api.html"
  content_type = "text/html; charset=UTF-8"
  etag         = filemd5("${path.module}/pages/api.html")
}

resource "aws_s3_object" "robots_txt" {
  bucket       = module.s3-web-assets.bucket_id
  key          = "robots.txt"
  source       = "${path.module}/pages/robots.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/pages/robots.txt")
}

resource "aws_s3_object" "sitemap_xml" {
  bucket = module.s3-web-assets.bucket_id
  key    = "sitemap.xml"
  content = templatefile("${path.module}/pages/sitemap.xml.tpl", {
    cloudfront_domain = aws_cloudfront_distribution.this.domain_name
  })
  content_type = "application/xml"
  etag = md5(templatefile("${path.module}/pages/sitemap.xml.tpl", {
    cloudfront_domain = aws_cloudfront_distribution.this.domain_name
  }))
}

# Favicon for CloudFront caching demonstration
# This demonstrates CloudFront caching with a long TTL
resource "aws_s3_object" "favicon" {
  count = fileexists("${path.module}/pages/favicon.ico") ? 1 : 0

  bucket       = module.s3-web-assets.bucket_id
  key          = "favicon.ico"
  source       = "${path.module}/pages/favicon.ico"
  content_type = "image/x-icon"
  etag         = filemd5("${path.module}/pages/favicon.ico")

  # Set Cache-Control header for long-term caching (1 year)
  # CloudFront will respect this header due to CachingOptimized policy
  cache_control = "public, max-age=31536000, immutable"
}

# S3 Bucket Policy for CloudFront OAC
data "aws_iam_policy_document" "s3_cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.s3-web-assets.bucket_arn}/*"]

    # Condition to restrict access to this specific CloudFront distribution
    # For OAC, CloudFront sends the exact distribution ARN as SourceArn
    # Using StringEquals as per AWS documentation for OAC (matches working test2)
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "web" {
  bucket = module.s3-web-assets.bucket_id
  policy = data.aws_iam_policy_document.s3_cloudfront.json
}

# WAF logs bucket for CloudFront WAF
# IMPORTANT: This bucket MUST be in us-east-1 region because CloudFront WAF
# logs can only be delivered to S3 buckets in us-east-1. The provider alias
# aws.us-east-1 ensures this, but if you see region errors, check that:
# 1. The provider alias is correctly passed to the module
# 2. No AWS environment variables (AWS_REGION, AWS_DEFAULT_REGION) are overriding
# 3. The bucket name doesn't already exist in another region
resource "aws_s3_bucket" "waf_logs" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0

  bucket        = "aws-waf-logs-${var.name_suffix}"
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name = "aws-waf-logs-${var.name_suffix}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0

  bucket = aws_s3_bucket.waf_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Lifecycle policy for WAF logs - auto-delete after 90 days for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0
  bucket   = aws_s3_bucket.waf_logs[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    # Transition to cheaper storage classes
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}
