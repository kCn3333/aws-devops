output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://eu-north-1.console.aws.amazon.com/cloudwatch/home?region=eu-north-1#dashboards:name=${aws_cloudwatch_dashboard.this.dashboard_name}"
}
