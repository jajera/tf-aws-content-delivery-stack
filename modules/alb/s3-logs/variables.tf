variable "name_prefix" {
  description = "Prefix for bucket name"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for bucket name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for ELB service account"
  type        = string
}

variable "force_destroy" {
  description = "Allow deletion of non-empty bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
