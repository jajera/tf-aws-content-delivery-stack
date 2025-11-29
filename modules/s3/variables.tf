variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = false
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

variable "bucket_policy_json" {
  description = "JSON policy document to attach to the bucket. If not provided, no policy will be attached."
  type        = string
  default     = null
}

variable "enable_bucket_policy" {
  description = "Whether to create a bucket policy. Set to true if bucket_policy_json is provided (even if unknown at plan time)."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "Object ownership setting for the bucket. Set to 'BucketOwnerPreferred' to enable ACLs, 'BucketOwnerEnforced' to disable ACLs (default)."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerPreferred", "BucketOwnerEnforced", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be one of: BucketOwnerPreferred, BucketOwnerEnforced, ObjectWriter"
  }
}

variable "acl_grants" {
  description = "List of ACL grants. Each grant should have 'id' (canonical user ID), 'type' ('CanonicalUser'), and 'permission' ('READ', 'WRITE', 'READ_ACP', 'WRITE_ACP', 'FULL_CONTROL'). Only used if object_ownership is 'BucketOwnerPreferred'."
  type = list(object({
    id         = string
    type       = string
    permission = string
  }))
  default = []
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket. Each rule should have 'id', 'status' ('Enabled' or 'Disabled'), optional 'expiration_days', and optional 'transitions' list with 'days' and 'storage_class'."
  type = list(object({
    id              = string
    status          = string
    expiration_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}
