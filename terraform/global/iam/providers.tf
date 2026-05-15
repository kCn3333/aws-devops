provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      Project   = "aws-devops"
      ManagedBy = "terraform"
    }
  }
}