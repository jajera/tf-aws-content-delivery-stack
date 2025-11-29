# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ownership controls (required for ACLs)
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

# Bucket ACL (only if grants are provided and ownership allows ACLs)
resource "aws_s3_bucket_acl" "this" {
  count  = length(var.acl_grants) > 0 && var.object_ownership == "BucketOwnerPreferred" ? 1 : 0
  bucket = aws_s3_bucket.this.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    dynamic "grant" {
      for_each = var.acl_grants
      content {
        grantee {
          id   = grant.value.id
          type = grant.value.type
        }
        permission = grant.value.permission
      }
    }

    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.this]
}

# Bucket policy (if provided)
# Use enable_bucket_policy flag to avoid count evaluation issues when policy depends on resources
resource "aws_s3_bucket_policy" "this" {
  count  = var.enable_bucket_policy ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json
}

# Lifecycle configuration (if rules are provided)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}

# Data source for canonical user ID (needed for ACLs)
data "aws_canonical_user_id" "current" {}
