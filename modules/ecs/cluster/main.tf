# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-${var.name_suffix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.name_suffix}-cluster"
    }
  )
}
