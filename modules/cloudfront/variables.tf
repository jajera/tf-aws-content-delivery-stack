variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource names"
  type        = string
}

variable "force_destroy" {
  description = "If true, Terraform will not prevent destruction of resources"
  type        = bool
  default     = false
}

variable "web_alb_arn" {
  description = "ARN of the Web ALB"
  type        = string
}

variable "api_alb_arn" {
  description = "ARN of the API ALB"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (deprecated - using data source instead)"
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "alb_origin_protocol_policy" {
  description = "Protocol policy for ALB origin (http-only, https-only, match-viewer)"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.alb_origin_protocol_policy)
    error_message = "ALB origin protocol policy must be one of: http-only, https-only, match-viewer."
  }
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_All"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "geo_restriction_type" {
  description = "Geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "enable_s3_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable WAF Web ACL for CloudFront distribution"
  type        = bool
  default     = false
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to Kinesis Firehose. Requires enable_waf to be true"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit per 5-minute period per IP address. Set to 0 to disable rate limiting"
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 0
    error_message = "Rate limit must be 0 or greater. Set to 0 to disable."
  }
}

variable "waf_allowed_methods" {
  description = "List of allowed HTTP methods. Requests with other methods will be blocked"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]

  validation {
    condition = alltrue([
      for method in var.waf_allowed_methods : contains(["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"], upper(method))
    ])
    error_message = "Allowed methods must be valid HTTP methods: GET, HEAD, OPTIONS, POST, PUT, PATCH, DELETE"
  }
}

variable "enable_cloudfront_access_logs" {
  description = "Enable CloudFront access logs to S3"
  type        = bool
  default     = false
}

variable "enable_custom_domain" {
  description = "If true, enables custom domain for CloudFront with ACM certificate and Route53 DNS records"
  type        = bool
  default     = false
}

variable "custom_domain_name" {
  description = "Custom domain name for CloudFront (e.g., web.example.com). Required if enable_custom_domain is true"
  type        = string
  default     = null
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com). Required if enable_custom_domain is true"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
