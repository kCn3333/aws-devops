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
