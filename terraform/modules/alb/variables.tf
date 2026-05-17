variable "project_name" {
  description = "Project name used as resource name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB (minimum 2)"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the validated ACM certificate for HTTPS"
  type        = string
}

variable "target_port" {
  description = "Port on the target (EC2/ECS) to forward traffic to"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path for ALB health checks"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP status codes considered healthy"
  type        = string
  default     = "200"
}
