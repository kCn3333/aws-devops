output "vpc_id" {
  description = "The ID of the dev VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 public IP — use this for SSH and browser"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "EC2 public DNS"
  value       = module.ec2.public_dns
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ~/.ssh/aws-devops-key ubuntu@${module.ec2.public_ip}"
}

output "alb_target_group_arn" {
  description = "ALB target group ARN — used by ECS service"
  value       = module.alb.target_group_arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.alb.security_group_id
}
