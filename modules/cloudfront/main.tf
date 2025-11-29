# Data source to get ALB DNS names
data "aws_lb" "web" {
  arn = var.web_alb_arn
}

data "aws_lb" "api" {
  arn = var.api_alb_arn
}

data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

# Route53 hosted zone data source (for custom domain)
data "aws_route53_zone" "this" {
  count = var.enable_custom_domain ? 1 : 0
  name  = var.route53_zone_name
}
