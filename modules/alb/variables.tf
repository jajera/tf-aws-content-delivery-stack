variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource names"
  type        = string
}

variable "alb_name" {
  description = "Name identifier for this ALB (e.g., 'web', 'api')"
  type        = string
}

variable "target_port" {
  description = "Port for the target group"
  type        = number
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alb_certificate_arn" {
  description = "ARN of ACM certificate for ALB HTTPS listener (optional)"
  type        = string
  default     = null
}

variable "enable_https" {
  description = "If true and certificate is provided, redirect HTTP to HTTPS. If false or no certificate, HTTP listener will forward to target group."
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "If true, Terraform will not prevent destruction of resources"
  type        = bool
  default     = false
}

variable "access_logs_bucket_id" {
  description = "S3 bucket ID for ALB access logs (shared bucket)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
