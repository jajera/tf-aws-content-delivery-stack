# Cluster outputs
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.cluster.cluster_name
}

# Service outputs
output "api_service_id" {
  description = "ID of the API ECS service"
  value       = module.service_api.service_id
}

output "api_service_name" {
  description = "Name of the API ECS service"
  value       = module.service_api.service_name
}

output "api_task_definition_arn" {
  description = "ARN of the API task definition"
  value       = module.service_api.task_definition_arn
}

output "web_service_id" {
  description = "ID of the Web ECS service"
  value       = module.service_web.service_id
}

output "web_service_name" {
  description = "Name of the Web ECS service"
  value       = module.service_web.service_name
}

output "web_task_definition_arn" {
  description = "ARN of the Web task definition"
  value       = module.service_web.task_definition_arn
}

# ECS Security Group outputs
output "api_ecs_security_group_id" {
  description = "ID of the API ECS security group"
  value       = module.service_api.ecs_security_group_id
}

output "web_ecs_security_group_id" {
  description = "ID of the Web ECS security group"
  value       = module.service_web.ecs_security_group_id
}
