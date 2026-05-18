variable "project_name" {
  description = "Project name used as resource name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS task security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks (public subnets when no NAT Gateway)"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to Fargate tasks - required when in public subnets without NAT"
  type        = bool
  default     = true
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN - ECS service registers tasks here"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID - ECS SG allows inbound from this SG only"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container (e.g. kcn333/clients-api:latest)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS task instances to run"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "HTTP path for container health check"
  type        = string
  default     = "/actuator/health/readiness"
}

variable "health_check_start_period" {
  description = "Grace period in seconds before health checks start (Spring Boot needs ~60s)"
  type        = number
  default     = 90
}

variable "rds_secret_arn" {
  description = "Secrets Manager ARN for RDS credentials - injected as env vars"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint hostname"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "clients_db"
}

variable "spring_profile" {
  description = "Spring Boot active profile"
  type        = string
  default     = "prod"
}
