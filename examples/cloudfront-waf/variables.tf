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
