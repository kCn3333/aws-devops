terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "kcn-terraform-state"
    key          = "environments/dev/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true # replaces deprecated dynamodb_tabledd
    encrypt      = true
  }
}
