#
# Network outputs
#
output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block assigned to the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (for ALBs/NAT)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets used by ECS"
  value       = module.vpc.private_subnet_ids
}

#
# ECS / ALB outputs
#
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].cluster_id : null
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = var.enable_ecs ? module.ecs[0].cluster_name : null
}

output "api_service_name" {
  description = "Name of the API ECS service"
  value       = var.enable_ecs ? module.ecs[0].api_service_name : null
}

output "web_service_name" {
  description = "Name of the Web ECS service"
  value       = var.enable_ecs ? module.ecs[0].web_service_name : null
}

output "api_alb_dns_name" {
  description = "DNS name of the API ALB"
  value       = var.enable_alb ? module.alb_api[0].alb_dns_name : null
}

output "api_alb_url" {
  description = "HTTP URL that hits the API ALB directly"
  value       = var.enable_alb ? format("http://%s", module.alb_api[0].alb_dns_name) : null
}

output "web_alb_dns_name" {
  description = "DNS name of the Web ALB"
  value       = var.enable_alb ? module.alb_web[0].alb_dns_name : null
}

output "web_alb_url" {
  description = "HTTP URL that hits the Web ALB directly"
  value       = var.enable_alb ? format("http://%s", module.alb_web[0].alb_dns_name) : null
}

output "web_alb_arn" {
  description = "ARN of the Web ALB"
  value       = var.enable_alb ? module.alb_web[0].alb_arn : null
}

output "api_alb_arn" {
  description = "ARN of the API ALB"
  value       = var.enable_alb ? module.alb_api[0].alb_arn : null
}

output "web_target_group_arn" {
  description = "Target group ARN for the Web service"
  value       = var.enable_alb ? module.alb_web[0].target_group_arn : null
}

output "api_target_group_arn" {
  description = "Target group ARN for the API service"
  value       = var.enable_alb ? module.alb_api[0].target_group_arn : null
}

output "web_listener_arns" {
  description = "ARNs of Web ALB listeners"
  value       = var.enable_alb ? module.alb_web[0].listener_arns : []
}

output "api_listener_arns" {
  description = "ARNs of API ALB listeners"
  value       = var.enable_alb ? module.alb_api[0].listener_arns : []
}

#
# CloudFront + S3 outputs
#
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].cloudfront_distribution_id : null
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].cloudfront_distribution_arn : null
}

output "cloudfront_domain_name" {
  description = "Domain name assigned by CloudFront"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].cloudfront_domain_name : null
}

output "cloudfront_url" {
  description = "HTTPS URL served via CloudFront"
  value       = var.enable_cloudfront && var.enable_alb ? format("https://%s", module.cloudfront[0].cloudfront_domain_name) : null
}

output "cloudfront_api_url" {
  description = "HTTPS URL for API endpoints served via CloudFront"
  value       = var.enable_cloudfront && var.enable_alb ? format("https://%s/api", module.cloudfront[0].cloudfront_domain_name) : null
}

output "custom_domain_url" {
  description = "HTTPS URL for the custom domain (if enabled)"
  value       = var.enable_cloudfront && var.enable_alb && var.enable_custom_domain ? module.cloudfront[0].custom_domain_url : null
}

output "custom_domain_api_url" {
  description = "HTTPS URL for API endpoints via custom domain (if enabled)"
  value       = var.enable_cloudfront && var.enable_alb && var.enable_custom_domain ? "${module.cloudfront[0].custom_domain_url}/api" : null
}

output "web_assets_bucket_name" {
  description = "Name of the S3 bucket that stores static web assets"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].s3_bucket_name : null
}

output "web_assets_bucket_domain_name" {
  description = "Regional domain name for the static asset bucket"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].s3_bucket_domain_name : null
}

#
# WAF outputs
#
output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL protecting CloudFront"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].waf_web_acl_id : null
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL protecting CloudFront"
  value       = var.enable_cloudfront && var.enable_alb ? module.cloudfront[0].waf_web_acl_arn : null
}
