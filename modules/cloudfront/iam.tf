
resource "aws_iam_role" "firehose" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0

  name = "${var.name_prefix}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "firehose" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0

  name = "${var.name_prefix}-firehose-policy"
  role = aws_iam_role.firehose[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.waf_logs[0].arn,
          "${aws_s3_bucket.waf_logs[0].arn}/*"
        ]
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.waf_logs
  ]
}

resource "aws_iam_service_linked_role" "waf_logging" {
  count = var.enable_waf && var.enable_waf_logging ? 1 : 0

  aws_service_name = "waf.amazonaws.com"
  description      = "Enables AWS WAF to deliver logs to Firehose"
}
