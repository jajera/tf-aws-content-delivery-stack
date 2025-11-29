variable "domain_name" {
  description = "Domain name for ALB HTTPS certificate (e.g., web.example.com). Required for HTTPS"
  type        = string
  default     = null
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com). Required for DNS validation of ACM certificate"
  type        = string
  default     = null
}
