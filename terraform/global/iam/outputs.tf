output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions — add to GitHub repository secrets"
  value       = aws_iam_role.github_actions.arn
}