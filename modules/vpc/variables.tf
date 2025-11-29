variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "subnet_bits" {
  description = "Number of bits to add to VPC CIDR for subnet calculation"
  type        = number
  default     = 8
}

variable "nat_gateway_per_az" {
  description = "If true, create one NAT Gateway per availability zone (high availability). If false, create a single NAT Gateway (cost savings)"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "force_destroy" {
  description = "If true, Terraform will not prevent destruction of resources"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
