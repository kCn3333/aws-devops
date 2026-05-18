variable "project_name" {
  description = "Project name used as resource name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for metric dimensions"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for metric dimensions"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metric dimensions"
  type        = string
}

variable "alb_target_group_arn_suffix" {
  description = "ALB target group ARN suffix for CloudWatch metric dimensions"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier for metric dimensions"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch dashboard metric widgets"
  type        = string
  default     = "eu-north-1"
}
