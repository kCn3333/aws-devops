provider "aws" {
  region = "eu-north-1"
}

resource "aws_default_vpc" "default_vpc" {

}

resource "aws_security_group" "http_example" {

  name   = "http_example"
  vpc_id = aws_default_vpc.default_vpc.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kcn_srv" {
  ami                    = data.aws_ami.ubuntu.id
  key_name               = "default-ec2-key"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.http_example.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  tags = {
    Name = "kCn server"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.aws_key_pair)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install nginx -y",
      "sudo systemctl enable --now nginx",
      "echo '<h1>Welcome to kCn server</h1> ${self.public_dns}' | sudo tee /var/www/html/index.html"
    ]
  }
}