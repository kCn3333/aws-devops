output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.this.id
}

output "ami_id" {
  description = "The AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "iam_role_name" {
  description = "Name of the EC2 IAM role - used to attach additional policies"
  value       = aws_iam_role.this.name
}
