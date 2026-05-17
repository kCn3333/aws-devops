module "vpc" {
  source = "../../modules/vpc"

  project_name         = "aws-devops"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["eu-north-1a", "eu-north-1b"]
  enable_nat_gateway   = false
}

module "ec2" {
  source = "../../modules/ec2"

  project_name = "aws-devops"
  environment  = "dev"

  # VPC module outputs wired directly as EC2 module inputs
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

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

  # nginx on EC2 listens on port 80, health check on /
  target_port          = 80
  health_check_path    = "/"
  health_check_matcher = "200"
}

# -----------------------------------------------------------------------------
# Register EC2 in ALB target group
# -----------------------------------------------------------------------------
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = module.alb.target_group_arn
  target_id        = module.ec2.instance_id
  port             = 80
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
