resource "random_id" "suffix" {
  byte_length = 4
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name_prefix             = var.name_prefix
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  subnet_bits             = var.subnet_bits
  nat_gateway_per_az      = var.nat_gateway_per_az
  flow_log_retention_days = var.flow_log_retention_days
  force_destroy           = var.force_destroy

  tags = var.tags
}

# Shared S3 bucket for ALB access logs (using ALB module's s3-logs submodule)
module "alb_logs_s3" {
  count = var.enable_alb ? 1 : 0

  source = "./modules/alb/s3-logs"

  name_prefix   = var.name_prefix
  name_suffix   = random_id.suffix.hex
  aws_region    = var.aws_region
  force_destroy = var.force_destroy
  tags          = var.tags
}

# Web ALB
module "alb_web" {
  count = var.enable_alb ? 1 : 0

  source = "./modules/alb"

  name_prefix                = var.name_prefix
  name_suffix                = random_id.suffix.hex
  alb_name                   = "web"
  target_port                = 80
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  aws_region                 = var.aws_region
  alb_certificate_arn        = var.alb_certificate_arn
  enable_https               = var.enable_https
  enable_deletion_protection = var.enable_deletion_protection
  force_destroy              = var.force_destroy
  access_logs_bucket_id      = module.alb_logs_s3[0].bucket_id

  tags = var.tags
}

# API ALB
module "alb_api" {
  count = var.enable_alb ? 1 : 0

  source = "./modules/alb"

  name_prefix                = var.name_prefix
  name_suffix                = random_id.suffix.hex
  alb_name                   = "api"
  target_port                = 8000
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  aws_region                 = var.aws_region
  alb_certificate_arn        = var.alb_certificate_arn
  enable_https               = var.enable_https
  enable_deletion_protection = var.enable_deletion_protection
  force_destroy              = var.force_destroy
  access_logs_bucket_id      = module.alb_logs_s3[0].bucket_id

  tags = var.tags
}

# ECS Module
module "ecs" {
  count = var.enable_ecs ? 1 : 0

  source = "./modules/ecs"

  name_prefix               = var.name_prefix
  name_suffix               = random_id.suffix.hex
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  aws_region                = var.aws_region
  log_retention_days        = var.log_retention_days
  enable_container_insights = var.enable_container_insights
  force_destroy             = var.force_destroy

  # ALB inputs (required - ECS depends on ALB)
  api_target_group_arn      = var.enable_alb ? module.alb_api[0].target_group_arn : null
  web_target_group_arn      = var.enable_alb ? module.alb_web[0].target_group_arn : null
  api_alb_security_group_id = var.enable_alb ? module.alb_api[0].alb_security_group_id : null
  web_alb_security_group_id = var.enable_alb ? module.alb_web[0].alb_security_group_id : null
  api_listener_arns         = var.enable_alb ? module.alb_api[0].listener_arns : []
  web_listener_arns         = var.enable_alb ? module.alb_web[0].listener_arns : []
  api_base_url              = var.enable_cloudfront && var.enable_alb ? "https://${module.cloudfront[0].cloudfront_domain_name}/api" : var.enable_alb ? "http://${module.alb_api[0].alb_dns_name}:80" : null

  tags = var.tags
}

# CloudFront Module
module "cloudfront" {
  count = var.enable_cloudfront && var.enable_alb ? 1 : 0

  source = "./modules/cloudfront"
  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  name_prefix                   = var.name_prefix
  name_suffix                   = random_id.suffix.hex
  force_destroy                 = var.force_destroy
  web_alb_arn                   = module.alb_web[0].alb_arn
  api_alb_arn                   = module.alb_api[0].alb_arn
  default_root_object           = var.default_root_object
  alb_origin_protocol_policy    = var.alb_origin_protocol_policy
  price_class                   = var.price_class
  geo_restriction_type          = var.geo_restriction_type
  geo_restriction_locations     = var.geo_restriction_locations
  enable_s3_versioning          = var.enable_s3_versioning
  enable_waf                    = var.enable_waf
  enable_waf_logging            = var.enable_waf_logging
  enable_cloudfront_access_logs = var.enable_cloudfront_access_logs
  enable_custom_domain          = var.enable_custom_domain
  custom_domain_name            = var.custom_domain_name
  route53_zone_name             = var.route53_zone_name
  waf_rate_limit                = var.waf_rate_limit
  waf_allowed_methods           = var.waf_allowed_methods
  tags                          = var.tags
}
