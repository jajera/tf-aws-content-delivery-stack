# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# ECS Cluster
module "cluster" {
  source = "./cluster"

  name_prefix               = var.name_prefix
  name_suffix               = var.name_suffix
  enable_container_insights = var.enable_container_insights

  tags = var.tags
}

# ECS Service - API
module "service_api" {
  source = "./service"

  name_prefix        = var.name_prefix
  service_name       = "api"
  cluster_id         = module.cluster.cluster_id
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  aws_region         = var.aws_region

  alb_security_group_id = var.api_alb_security_group_id
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  task_role_arn         = aws_iam_role.ecs_task.arn

  container_name  = "api"
  container_image = "ghcr.io/platformfuzz/geomag-api-image:latest"
  container_port  = 8000
  task_cpu        = 256
  task_memory     = 512
  desired_count   = length(var.private_subnet_ids)

  target_group_arn = var.api_target_group_arn

  health_check_command = [
    "CMD-SHELL",
    "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)\" || exit 1"
  ]

  log_retention_days = var.log_retention_days
  force_destroy      = var.force_destroy

  tags = var.tags
}

# ECS Service - Web
module "service_web" {
  source = "./service"

  name_prefix        = var.name_prefix
  service_name       = "web"
  cluster_id         = module.cluster.cluster_id
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  aws_region         = var.aws_region

  alb_security_group_id = var.web_alb_security_group_id
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  task_role_arn         = aws_iam_role.ecs_task.arn

  container_name  = "web"
  container_image = "ghcr.io/platformfuzz/geomag-web-image:latest"
  container_port  = 80
  task_cpu        = 256
  task_memory     = 512
  desired_count   = length(var.private_subnet_ids)

  target_group_arn = var.web_target_group_arn

  environment_variables = [
    {
      name  = "API_BASE_URL"
      value = var.api_base_url
    }
  ]

  health_check_command = [
    "CMD-SHELL",
    "curl -f http://localhost:80/ || exit 1"
  ]

  log_retention_days = var.log_retention_days
  force_destroy      = var.force_destroy

  tags = var.tags
}
