variable "project_name" {
  description = "Project name used as resource name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (minimum 2 AZs)"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to RDS on port 5432"
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "clients_db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage size in GB"
  type        = number
  default     = 20
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion - set to false in production"
  type        = bool
  default     = true
}
