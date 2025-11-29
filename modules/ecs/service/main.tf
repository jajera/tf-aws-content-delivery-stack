# CloudWatch Log Group for ECS tasks (with prevent_destroy)
resource "aws_cloudwatch_log_group" "ecs_protected" {
  count = var.force_destroy ? 0 : 1

  name              = "/ecs/${var.name_prefix}-${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# CloudWatch Log Group for ECS tasks (without prevent_destroy)
resource "aws_cloudwatch_log_group" "ecs_unprotected" {
  count = var.force_destroy ? 1 : 0

  name              = "/ecs/${var.name_prefix}-${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Local value to reference the log group (whichever one is created)
locals {
  ecs_log_group_name = var.force_destroy ? aws_cloudwatch_log_group.ecs_unprotected[0].name : aws_cloudwatch_log_group.ecs_protected[0].name
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs" {
  name        = "${var.name_prefix}-${var.service_name}-ecs-sg"
  description = "Security group for ECS tasks - allows traffic from ALB on port ${var.container_port} for ${var.service_name}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.service_name}-ecs-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name_prefix}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.ecs_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = var.environment_variables

      healthCheck = var.health_check_command != null ? {
        command     = var.health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      } : null
    }
  ])

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "${var.name_prefix}-${var.service_name}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-${var.service_name}"
    }
  )
}
