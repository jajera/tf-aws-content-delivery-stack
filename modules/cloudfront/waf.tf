
resource "aws_wafv2_web_acl" "this" {
  count       = var.enable_waf ? 1 : 0
  provider    = aws.us-east-1
  name        = "${var.name_prefix}-waf"
  description = "WAF for CloudFront distribution with rate limiting and method restrictions"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule - blocks IPs that exceed the rate limit
  dynamic "rule" {
    for_each = var.waf_rate_limit > 0 ? [1] : []
    content {
      name     = "RateLimitRule"
      priority = 1

      statement {
        rate_based_statement {
          limit              = var.waf_rate_limit
          aggregate_key_type = "IP"
        }
      }

      action {
        block {}
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-rate-limit"
        sampled_requests_enabled   = true
      }
    }
  }

  # HTTP method restriction rule - blocks disallowed methods
  # Logic: NOT (method matches allowed methods) → BLOCK
  # This rule blocks any HTTP method that is NOT in the allowed list
  #
  # Handles multiple scenarios:
  # 1. Case-insensitive matching: HTTP methods can come in any case (GET, get, Get, etc.)
  #    - Text transformation converts incoming method to lowercase
  #    - Regex pattern is built in lowercase to match transformed value
  # 2. Variable normalization: waf_allowed_methods can contain methods in any case
  #    - lower() normalizes variable values to lowercase for regex pattern
  # 3. Dynamic method list: Supports any combination of standard HTTP methods
  rule {
    name     = "MethodRestrictionRule"
    priority = var.waf_rate_limit > 0 ? 2 : 1

    statement {
      not_statement {
        statement {
          regex_match_statement {
            # Normalize allowed methods to lowercase for regex pattern
            # This handles cases where variable contains mixed case (GET, get, Get, etc.)
            regex_string = "^(${join("|", [for method in var.waf_allowed_methods : lower(method)])})$"

            field_to_match {
              method {}
            }

            # Transform incoming HTTP method to lowercase before regex matching
            # This ensures case-insensitive matching (GET, get, Get all match)
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-method-restriction"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf-metric"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  provider = aws.us-east-1
  count    = var.enable_waf && var.enable_waf_logging ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this[0].arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs[0].arn]

  # Redact sensitive fields for data protection and cost optimization
  # Redacting these fields reduces log size and protects sensitive data
  redacted_fields {
    # Redact query strings (may contain API keys, tokens, sensitive parameters)
    single_header {
      name = "query_string"
    }
  }

  redacted_fields {
    # Redact Authorization header (contains tokens, API keys)
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    # Redact Cookie header (contains session data, tokens)
    single_header {
      name = "cookie"
    }
  }

  depends_on = [
    aws_kinesis_firehose_delivery_stream.waf_logs,
    aws_iam_role.firehose,
    aws_iam_role_policy.firehose,
    aws_iam_service_linked_role.waf_logging
  ]
}
