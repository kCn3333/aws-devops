output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "ECS tasks security group ID - add to RDS allowed SGs"
  value       = aws_security_group.ecs.id
}

output "task_execution_role_arn" {
  description = "Task execution role ARN"
  value       = aws_iam_role.task_execution.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.this.name
}
