
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0

  name        = "aws-waf-logs-${data.aws_caller_identity.current.account_id}-${var.name_suffix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose[0].arn
    bucket_arn          = aws_s3_bucket.waf_logs[0].arn
    prefix              = "waf-logs/"
    error_output_prefix = "waf-logs-errors/"

    buffering_size     = 5
    buffering_interval = 60
    compression_format = "GZIP"
  }

  tags = var.tags

  depends_on = [
    aws_s3_bucket.waf_logs,
    aws_s3_bucket_server_side_encryption_configuration.waf_logs,
    aws_iam_role.firehose,
    aws_iam_role_policy.firehose
  ]
}

# Resource policy for Firehose to allow WAF to write logs
# Note: Kinesis Firehose doesn't support resource policies in Terraform,
# but for CloudFront WAF logging, AWS handles permissions automatically.
# The issue might be that the stream needs to be fully active first.
