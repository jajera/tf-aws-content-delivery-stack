# CloudFront + WAF module

End‑to‑end static + dynamic delivery stack used by this repository.
The module builds:

- A private `web-assets` bucket (via the local S3 submodule) with Object Access Control for CloudFront plus managed error-page uploads.
- A CloudFront distribution with three origins (S3 for static/error assets, web ALB, API ALB) and ordered cache behaviours for `api/`, OpenAPI, error files and static patterns.
- AWS-managed WAFv2 Web ACL scoped to CloudFront, optional logging through a Kinesis Firehose stream and dedicated `aws-waf-logs-*` bucket in `us-east-1`.

## Usage

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  providers = {
    aws           = aws               # workload region (e.g. ap-southeast-2)
    aws.us-east-1 = aws.us-east-1     # us-east-1 for CloudFront / WAF / logging
  }

  name_prefix = var.name_prefix
  name_suffix = random_id.suffix.hex

  web_alb_arn = module.ecs.web_alb_arn
  api_alb_arn = module.ecs.api_alb_arn

  default_root_object = "index.html"
  enable_waf_logging  = true

  tags = var.tags
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name_prefix` | Logical prefix for all resources | string | n/a |
| `name_suffix` | Random/unique suffix appended to buckets/streams | string | n/a |
| `force_destroy` | Allow tearing down buckets with data | bool | `false` |
| `web_alb_arn` | ARN of the public web ALB origin | string | n/a |
| `api_alb_arn` | ARN of the API ALB origin | string | n/a |
| `alb_dns_name` | Backwards compatibility value (unused) | string | `null` |
| `default_root_object` | CloudFront root document | string | `index.html` |
| `alb_origin_protocol_policy` | `http-only`, `https-only`, or `match-viewer` | string | `https-only` |
| `price_class` | CloudFront price class | string | `PriceClass_All` |
| `geo_restriction_type` | `none`, `whitelist`, `blacklist` | string | `none` |
| `geo_restriction_locations` | ISO country codes when geo filtering is enabled | list(string) | `[]` |
| `enable_s3_versioning` | Toggle web-assets bucket versioning | bool | `false` |
| `enable_waf_logging` | Provision Firehose + S3 + logging config | bool | `false` |
| `waf_rate_limit` | Rate limit per 5-minute period per IP address. Set to 0 to disable rate limiting | number | `2000` |
| `waf_allowed_methods` | List of allowed HTTP methods. Requests with other methods will be blocked | list(string) | `["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]` |
| `enable_cloudfront_access_logs` | Enable CloudFront access logs to S3 | bool | `false` |
| `enable_custom_domain` | Enable custom domain with ACM certificate and Route53 records | bool | `false` |
| `custom_domain_name` | Custom domain name (e.g., web.example.com) | string | `null` |
| `route53_zone_name` | Route53 hosted zone name (e.g., example.com) | string | `null` |
| `tags` | Map of tags applied to every resource | map(string) | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `s3_bucket_id` | ID of the managed `web-assets` bucket |
| `s3_bucket_arn` | ARN of the `web-assets` bucket |
| `s3_bucket_name` | Name of the `web-assets` bucket |
| `s3_bucket_domain_name` | Regional endpoint for the static bucket |
| `cloudfront_distribution_id` | Distribution ID for deployments/invalidation |
| `cloudfront_distribution_arn` | Distribution ARN |
| `cloudfront_domain_name` | Public domain (e.g. `dXXXX.cloudfront.net`) |
| `cloudfront_hosted_zone_id` | Hosted zone ID for CloudFront distribution |
| `custom_domain_name` | Custom domain name (if enabled) |
| `custom_domain_url` | HTTPS URL for the custom domain (if enabled) |
| `acm_certificate_arn` | ARN of the ACM certificate (if custom domain is enabled) |
| `waf_web_acl_id` | ID of the WAF Web ACL protecting CloudFront |
| `waf_web_acl_arn` | ARN of the WAF Web ACL protecting CloudFront |
| `waf_logs_bucket_id` | ID of the S3 bucket for WAF logs (if enabled) |
| `waf_logs_bucket_arn` | ARN of the S3 bucket for WAF logs (if enabled) |
| `waf_logs_bucket_name` | Name of the S3 bucket for WAF logs (if enabled) |
| `cloudfront_access_logs_bucket_id` | ID of the S3 bucket for CloudFront access logs (if enabled) |
| `cloudfront_access_logs_bucket_arn` | ARN of the S3 bucket for CloudFront access logs (if enabled) |
| `cloudfront_access_logs_bucket_name` | Name of the S3 bucket for CloudFront access logs (if enabled) |
