variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
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

variable "force_destroy" {
  description = "If true, Terraform will not prevent destruction of resources"
  type        = bool
  default     = false
}

variable "api_base_url" {
  description = "Base URL for API calls (e.g., http://alb-dns-name:80 or https://cloudfront-domain/api for caching optimization)"
  type        = string
}

variable "api_target_group_arn" {
  description = "ARN of the API ALB target group"
  type        = string
}

variable "web_target_group_arn" {
  description = "ARN of the Web ALB target group"
  type        = string
}

variable "api_alb_security_group_id" {
  description = "ID of the API ALB security group (for ECS security group ingress rules)"
  type        = string
}

variable "web_alb_security_group_id" {
  description = "ID of the Web ALB security group (for ECS security group ingress rules)"
  type        = string
}

variable "api_listener_arns" {
  description = "ARNs of API ALB listeners (for ECS service dependencies)"
  type        = list(string)
  default     = []
}

variable "web_listener_arns" {
  description = "ARNs of Web ALB listeners (for ECS service dependencies)"
  type        = list(string)
  default     = []
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
