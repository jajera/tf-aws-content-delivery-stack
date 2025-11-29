# ECS Service Submodule

This submodule creates a complete ECS Fargate service including task definition, service, security group, and CloudWatch log group. It can be used independently or as part of a larger ECS setup.

## Usage

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| service_name | Name of the service (e.g., 'api', 'web') | string | - | yes |
| cluster_id | ID of the ECS cluster | string | - | yes |
| vpc_id | ID of the VPC | string | - | yes |
| private_subnet_ids | List of private subnet IDs for ECS tasks | list(string) | - | yes |
| aws_region | AWS region | string | - | yes |
| alb_security_group_id | ID of the ALB security group | string | - | yes |
| execution_role_arn | ARN of the ECS task execution role | string | - | yes |
| task_role_arn | ARN of the ECS task role | string | - | yes |
| container_image | Container image to use | string | - | yes |
| container_port | Port the container listens on | number | - | yes |
| container_name | Name of the container | string | `app` | no |
| task_cpu | CPU units for the task | number | `256` | no |
| task_memory | Memory for the task in MB | number | `512` | no |
| desired_count | Desired number of tasks | number | `1` | no |
| assign_public_ip | Whether to assign public IP to tasks | bool | `false` | no |
| target_group_arn | ARN of the ALB target group (optional) | string | `null` | no |
| environment_variables | Environment variables for the container | list(map(string)) | `[]` | no |
| health_check_command | Health check command (null to disable) | list(string) | `null` | no |
| log_retention_days | Number of days to retain CloudWatch logs | number | `7` | no |
| force_destroy | If true, Terraform will not prevent destruction of resources | bool | `false` | no |
| tags | Tags to apply to all resources | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_id | ID of the ECS service |
| service_name | Name of the ECS service |
| task_definition_arn | ARN of the task definition |
| ecs_security_group_id | ID of the ECS security group |
| log_group_name | Name of the CloudWatch log group |
