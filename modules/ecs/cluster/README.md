# ECS Cluster Submodule

This submodule creates an ECS cluster that can be used independently or as part of a larger ECS setup.

## Usage

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | - | yes |
| name_suffix | Suffix for resource names | string | - | yes |
| enable_container_insights | Enable CloudWatch Container Insights | bool | `false` | no |
| tags | Tags to apply to all resources | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
