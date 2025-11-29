output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "listener_arns" {
  description = "ARNs of ALB listeners (for dependency management)"
  value = concat(
    aws_lb_listener.http_redirect[*].arn,
    aws_lb_listener.http_forward[*].arn,
    aws_lb_listener.https[*].arn
  )
}
