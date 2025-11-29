variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "subnet_bits" {
  description = "Number of bits to add to VPC CIDR for subnet calculation"
  type        = number
  default     = 8
}

variable "nat_gateway_per_az" {
  description = "If true, create one NAT Gateway per availability zone (high availability). If false, create a single NAT Gateway (cost savings)"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "Flow log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "force_destroy" {
  description = "If true, Terraform will not prevent destruction of resources"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ARN of ACM certificate for ALB HTTPS listener (optional)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "If true and certificate is provided, redirect HTTP to HTTPS. If false or no certificate, HTTP listener will forward to target group."
  type        = bool
  default     = false
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "alb_origin_protocol_policy" {
  description = "Protocol policy for ALB origin"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.alb_origin_protocol_policy)
    error_message = "ALB origin protocol policy must be one of: http-only, https-only, match-viewer."
  }
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_All"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "geo_restriction_type" {
  description = "Geo restriction type"
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
  description = "WAF rate limit per 5-minute period per IP address. Set to 0 to disable rate limiting"
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 0
    error_message = "Rate limit must be 0 or greater. Set to 0 to disable."
  }
}

variable "waf_allowed_methods" {
  description = "List of allowed HTTP methods for WAF. Requests with other methods will be blocked"
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

variable "enable_alb" {
  description = "If true, creates Application Load Balancer (ALB) for routing traffic to ECS services"
  type        = bool
  default     = false
}

variable "enable_ecs" {
  description = "If true, creates ECS cluster and services. Requires ALB to be enabled"
  type        = bool
  default     = false

  validation {
    condition     = var.enable_ecs ? var.enable_alb : true
    error_message = "ECS requires ALB to be enabled. Set enable_alb = true when enable_ecs = true"
  }
}

variable "enable_cloudfront" {
  description = "If true, creates CloudFront distribution and web container will use CloudFront URL for API calls (enables caching). If false, CloudFront is not created and uses ALB directly. Requires ALB to be enabled"
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
  default = {
    ManagedBy = "Terraform"
  }
}
