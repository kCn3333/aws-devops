provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "kcn_srv" {
  ami           = "ami-080254318c2d8932f"
  instance_type = "t3.micro"

  tags = {
    Name = "kCn server"
  }
}