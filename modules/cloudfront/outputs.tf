output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.s3-web-assets.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3-web-assets.bucket_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3-web-assets.bucket_name
}

output "s3_bucket_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = module.s3-web-assets.bucket_regional_domain_name
}

output "cloudfront_access_logs_bucket_id" {
  description = "ID of the S3 bucket for CloudFront access logs (if enabled)"
  value       = var.enable_cloudfront_access_logs ? module.s3-cloudfront-access-logs[0].bucket_id : null
}

output "cloudfront_access_logs_bucket_arn" {
  description = "ARN of the S3 bucket for CloudFront access logs (if enabled)"
  value       = var.enable_cloudfront_access_logs ? module.s3-cloudfront-access-logs[0].bucket_arn : null
}

output "cloudfront_access_logs_bucket_name" {
  description = "Name of the S3 bucket for CloudFront access logs (if enabled)"
  value       = var.enable_cloudfront_access_logs ? module.s3-cloudfront-access-logs[0].bucket_name : null
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "custom_domain_name" {
  description = "Custom domain name (if enabled)"
  value       = var.enable_custom_domain ? var.custom_domain_name : null
}

output "custom_domain_url" {
  description = "HTTPS URL for the custom domain (if enabled)"
  value       = var.enable_custom_domain ? "https://${var.custom_domain_name}" : null
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate (if custom domain is enabled)"
  value       = var.enable_custom_domain ? aws_acm_certificate.cloudfront[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL protecting CloudFront (null if WAF is disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].id : null
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL protecting CloudFront (null if WAF is disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
}

output "waf_logs_bucket_id" {
  description = "ID of the S3 bucket for WAF logs (null if WAF or logging is disabled)"
  value       = var.enable_waf && var.enable_waf_logging ? aws_s3_bucket.waf_logs[0].id : null
}

output "waf_logs_bucket_arn" {
  description = "ARN of the S3 bucket for WAF logs (null if WAF or logging is disabled)"
  value       = var.enable_waf && var.enable_waf_logging ? aws_s3_bucket.waf_logs[0].arn : null
}

output "waf_logs_bucket_name" {
  description = "Name of the S3 bucket for WAF logs (null if WAF or logging is disabled)"
  value       = var.enable_waf && var.enable_waf_logging ? aws_s3_bucket.waf_logs[0].bucket : null
}
