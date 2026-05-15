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
  public_key       = file("~/.ssh/aws-devops-key.pub")
  root_volume_size = 20
}