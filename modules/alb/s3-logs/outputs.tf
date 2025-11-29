output "bucket_id" {
  description = "ID of the S3 bucket for ALB logs"
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for ALB logs"
  value       = module.s3.bucket_arn
}

output "bucket_name" {
  description = "Name of the S3 bucket for ALB logs"
  value       = module.s3.bucket_name
}
