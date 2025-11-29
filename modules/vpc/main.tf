# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.vpc_flow_logs_protected,
    aws_cloudwatch_log_group.vpc_flow_logs_unprotected
  ]
}

# Internet Gateway (always needed - for public subnets or for NAT gateways)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.nat_gateway_per_az ? length(var.availability_zones) : 1

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = var.nat_gateway_per_az ? "${var.name_prefix}-nat-eip-${count.index + 1}" : "${var.name_prefix}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  count = var.nat_gateway_per_az ? length(var.availability_zones) : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.nat_gateway_per_az ? aws_subnet.public[count.index].id : aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name = var.nat_gateway_per_az ? "${var.name_prefix}-nat-${count.index + 1}" : "${var.name_prefix}-nat"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# Public Subnets (used for NAT Gateway placement)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
      Type = "public"
    }
  )
}

# Private Subnets (for ECS tasks)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
      Type = "private"
    }
  )
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route tables for private subnets
# If nat_gateway_per_az is true: one route table per AZ (one per NAT Gateway)
# If nat_gateway_per_az is false: single route table for all private subnets
resource "aws_route_table" "private" {
  count = var.nat_gateway_per_az ? length(var.availability_zones) : 1

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_per_az ? aws_nat_gateway.this[count.index].id : aws_nat_gateway.this[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = var.nat_gateway_per_az ? "${var.name_prefix}-private-rt-${count.index + 1}" : "${var.name_prefix}-private-rt"
    }
  )
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.nat_gateway_per_az ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# CloudWatch Log Group for VPC Flow Logs (with prevent_destroy)
resource "aws_cloudwatch_log_group" "vpc_flow_logs_protected" {
  count = var.force_destroy ? 0 : 1

  name              = "/aws/vpc/${var.name_prefix}-flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# CloudWatch Log Group for VPC Flow Logs (without prevent_destroy)
resource "aws_cloudwatch_log_group" "vpc_flow_logs_unprotected" {
  count = var.force_destroy ? 1 : 0

  name              = "/aws/vpc/${var.name_prefix}-flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = var.tags
}

# Local value to reference the log group (whichever one is created)
locals {
  vpc_flow_logs_arn = var.force_destroy ? aws_cloudwatch_log_group.vpc_flow_logs_unprotected[0].arn : aws_cloudwatch_log_group.vpc_flow_logs_protected[0].arn
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy for VPC Flow Logs
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          local.vpc_flow_logs_arn,
          "${local.vpc_flow_logs_arn}:*"
        ]
      },
      {
        Sid    = "ReadLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = local.vpc_flow_logs_arn
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = local.vpc_flow_logs_arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id

  depends_on = [
    aws_cloudwatch_log_group.vpc_flow_logs_protected,
    aws_cloudwatch_log_group.vpc_flow_logs_unprotected
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-flow-logs"
    }
  )
}
