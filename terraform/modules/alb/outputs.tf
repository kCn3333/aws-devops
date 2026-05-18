output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "DNS name of the ALB - use this as CNAME target in Cloudflare"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group - used by ECS service in Lesson 10"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "Security group ID of the ALB - used to restrict EC2/ECS ingress"
  value       = aws_security_group.alb.id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics dimensions"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch metrics dimensions"
  value       = aws_lb_target_group.this.arn_suffix
}