provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "aws-devops-portfolio"
      ManagedBy   = "terraform"
    }
  }
}
