output "endpoint" {
  description = "RDS instance endpoint (host only, without port)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN - grant read access to ECS task role"
  value       = aws_secretsmanager_secret.rds.arn
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.rds.name
}

output "security_group_id" {
  description = "RDS security group ID - add ECS SG to allowed_security_group_ids"
  value       = aws_security_group.rds.id
}
