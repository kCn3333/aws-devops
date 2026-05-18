module "vpc" {
  source               = "../../modules/vpc"
  project_name         = "aws-devops"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["eu-north-1a", "eu-north-1b"]
  enable_nat_gateway   = false
}

module "ec2" {
  source           = "../../modules/ec2"
  project_name     = "aws-devops"
  environment      = "dev"
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_ids[0]
  instance_type    = "t3.micro"
  key_name         = "aws-devops-dev-key"
  public_key       = var.ec2_public_key
  root_volume_size = 20
}

module "acm" {
  source      = "../../modules/acm"
  domain_name = "devops.kcn333.com"
}

module "alb" {
  source = "../../modules/alb"

  project_name      = "aws-devops"
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn

  # clients-api listens on 8080, health check on Spring Boot readiness endpoint
  target_port          = 8080
  target_type          = "ip"
  health_check_path    = "/actuator/health/readiness"
  health_check_matcher = "200"
}

module "rds" {
  source       = "../../modules/rds"
  project_name = "aws-devops"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  # Allow both EC2 (bastion) and ECS tasks to connect
  allowed_security_group_ids = [
    module.ec2.security_group_id,
    module.ecs.security_group_id
  ]

  db_name             = "clients_db"
  db_username         = "dbadmin"
  engine_version      = "17"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  skip_final_snapshot = true
}

module "ecs" {
  source = "../../modules/ecs"

  project_name = "aws-devops"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id

  # Public subnets + public IP because no NAT Gateway
  subnet_ids       = module.vpc.public_subnet_ids
  assign_public_ip = true

  # clients-api from Docker Hub
  container_image = "kcn333/clients-api:latest"
  container_port  = 8080
  cpu             = 256
  memory          = 512
  desired_count   = 1

  # ALB integration
  alb_target_group_arn  = module.alb.target_group_arn
  alb_security_group_id = module.alb.security_group_id

  # Database
  rds_secret_arn = module.rds.secret_arn
  rds_endpoint   = module.rds.endpoint
  db_name        = "clients_db"

  # Spring Boot needs ~60s to start - 90s grace period before health checks
  health_check_path         = "/actuator/health/readiness"
  health_check_start_period = 90
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name = "aws-devops"
  environment  = "dev"
  alarm_email  = var.alarm_email

  ecs_cluster_name = module.ecs.cluster_id
  ecs_service_name = module.ecs.service_name

  alb_arn_suffix              = module.alb.arn_suffix
  alb_target_group_arn_suffix = module.alb.target_group_arn_suffix

  rds_instance_id = module.rds.instance_id
}

# IAM policy - EC2 can read RDS secret (bastion access)
resource "aws_iam_role_policy" "ec2_secrets" {
  name = "ec2-read-rds-secret"
  role = module.ec2.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [module.rds.secret_arn]
    }]
  })
}

# -----------------------------------------------------------------------------
# Allow traffic from ALB SG to EC2 SG
# Replaces the current "allow all on port 80" rule
# -----------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id            = module.ec2.security_group_id
  description                  = "Allow HTTP from ALB only"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.alb.security_group_id
}
