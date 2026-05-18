# -----------------------------------------------------------------------------
# Generate secure random password
# -----------------------------------------------------------------------------
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}|;:,.<>?"
  # RDS allows special chars but NOT: @, /, ", space
}

# -----------------------------------------------------------------------------
# Secrets Manager — store credentials as JSON
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "rds" {
  name                    = "${var.project_name}/${var.environment}/rds"
  description             = "RDS PostgreSQL credentials for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 0 # Immediate deletion in dev — use 7+ in prod

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-secret"
  }
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
    url      = "jdbc:postgresql://${aws_db_instance.this.address}:${aws_db_instance.this.port}/${var.db_name}"
  })
}

# -----------------------------------------------------------------------------
# Security Group — RDS
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL - allow only from app layer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.rds.id
  description                  = "Allow PostgreSQL from app security group"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}

# -----------------------------------------------------------------------------
# DB Subnet Group — RDS must span at least 2 AZs
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for ${var.project_name} ${var.environment} RDS"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# RDS Instance
# -----------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true
  max_allocated_storage = 100 # Enable autoscaling up to 100GB

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # Private subnet — no public access

  # High availability — disabled for dev (saves cost)
  multi_az = false

  # Backup
  backup_retention_period = 1 # 1 day backup window
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Deletion protection — disabled for dev
  deletion_protection = false
  skip_final_snapshot = var.skip_final_snapshot

  # Performance Insights — free for t3.micro
  performance_insights_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }

  # Wait for secret to be created before instance
  depends_on = [aws_secretsmanager_secret.rds]
}
