# ECS Module

This module creates an ECS Fargate cluster with API and Web services, including security groups, IAM roles, and CloudWatch logging. The module uses reusable submodules for the cluster and services.

## Features

- ECS cluster with optional Container Insights
- Two ECS Fargate services (API and Web)
- IAM roles (task execution and task role)
- Security groups for ECS tasks (allows traffic from ALB)
- CloudWatch log groups (per service)
- Health check configuration
- Configurable CPU and memory
- Automatic scaling based on number of availability zones

## Architecture

The module is composed of reusable submodules:

- **`cluster/`** - ECS cluster (can be used independently)
- **`service/`** - Complete ECS service including task definition, service, security group, and log group (can be used independently)

## Usage

```hcl
module "ecs" {
  source = "./modules/ecs"

  name_prefix        = "my-app"
  name_suffix        = random_id.suffix.hex
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = "ap-southeast-2"

  # ALB configuration (required - ECS depends on ALB)
  api_target_group_arn      = module.alb_api.target_group_arn
  web_target_group_arn      = module.alb_web.target_group_arn
  api_alb_security_group_id = module.alb_api.alb_security_group_id
  web_alb_security_group_id = module.alb_web.alb_security_group_id
  api_listener_arns         = module.alb_api.listener_arns
  web_listener_arns         = module.alb_web.listener_arns
  api_base_url              = "http://${module.alb_api.alb_dns_name}:80"

  log_retention_days        = 7
  enable_container_insights = false
  force_destroy             = false

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| name_suffix | Suffix for resource names (typically random ID) | string | - | yes |
| vpc_id | ID of the VPC | string | - | yes |
| private_subnet_ids | List of private subnet IDs for ECS tasks | list(string) | - | yes |
| aws_region | AWS region | string | - | yes |
| api_target_group_arn | ARN of the API ALB target group | string | - | yes |
| web_target_group_arn | ARN of the Web ALB target group | string | - | yes |
| api_alb_security_group_id | ID of the API ALB security group | string | - | yes |
| web_alb_security_group_id | ID of the Web ALB security group | string | - | yes |
| api_base_url | Base URL for API calls (used by Web service) | string | - | yes |
| api_listener_arns | ARNs of API ALB listeners (for dependencies) | list(string) | `[]` | no |
| web_listener_arns | ARNs of Web ALB listeners (for dependencies) | list(string) | `[]` | no |
| log_retention_days | Number of days to retain CloudWatch logs | number | `7` | no |
| enable_container_insights | Enable CloudWatch Container Insights | bool | `false` | no |
| force_destroy | If true, Terraform will not prevent destruction of resources | bool | `false` | no |
| tags | Tags to apply to all resources | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| api_service_id | ID of the API ECS service |
| api_service_name | Name of the API ECS service |
| api_task_definition_arn | ARN of the API task definition |
| web_service_id | ID of the Web ECS service |
| web_service_name | Name of the Web ECS service |
| web_task_definition_arn | ARN of the Web task definition |
| api_ecs_security_group_id | ID of the API ECS security group |
| web_ecs_security_group_id | ID of the Web ECS security group |

## Services

The module creates two ECS Fargate services:

### API Service

- Container image: `ghcr.io/platformfuzz/geomag-api-image:latest`
- Container port: `8000`
- CPU: `256` units
- Memory: `512` MB
- Desired count: Number of availability zones (one task per AZ)
- Health check: Python-based HTTP health check on `/health` endpoint

### Web Service

- Container image: `ghcr.io/platformfuzz/geomag-web-image:latest`
- Container port: `80`
- CPU: `256` units
- Memory: `512` MB
- Desired count: Number of availability zones (one task per AZ)
- Health check: `curl`-based health check
- Environment variable: `API_BASE_URL` (points to API ALB)

## CloudWatch Logs

Each service has its own CloudWatch log group:

- API service: `/ecs/{name_prefix}-api`
- Web service: `/ecs/{name_prefix}-web`

Log groups are created per service (not cluster-level) for better isolation and management.

## Submodules

### Using Cluster Submodule Independently

```hcl
module "ecs_cluster" {
  source = "./modules/ecs/cluster"

  name_prefix             = "my-app"
  name_suffix             = random_id.suffix.hex
  enable_container_insights = true

  tags = {
    Environment = "production"
  }
}
```

### Using Service Submodule Independently

```hcl
module "ecs_service" {
  source = "./modules/ecs/service"

  name_prefix        = "my-app"
  service_name       = "api"
  cluster_id         = module.ecs_cluster.cluster_id
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = "ap-southeast-2"

  alb_security_group_id = module.alb.alb_security_group_id
  execution_role_arn    = module.ecs_iam.execution_role_arn
  task_role_arn         = module.ecs_iam.task_role_arn

  container_image = "my-app:latest"
  container_port  = 8000
  target_group_arn = module.alb.target_group_arn

  tags = {
    Environment = "production"
  }
}
```

See the submodule READMEs for more details:

- [`cluster/README.md`](./cluster/README.md)
- [`service/README.md`](./service/README.md)
