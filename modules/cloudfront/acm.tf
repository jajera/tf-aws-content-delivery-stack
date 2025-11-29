# ACM Certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us-east-1
  count    = var.enable_custom_domain ? 1 : 0

  domain_name       = var.custom_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cloudfront-cert"
    }
  )
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us-east-1
  count    = var.enable_custom_domain ? 1 : 0

  certificate_arn = aws_acm_certificate.cloudfront[0].arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}
