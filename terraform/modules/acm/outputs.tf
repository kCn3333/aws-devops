output "certificate_arn" {
  description = "ARN of the ACM certificate (unvalidated - use validated_certificate_arn after validation)"
  value       = aws_acm_certificate.this.arn
}

output "domain_validation_options" {
  description = "DNS records required to validate the certificate"
  value       = aws_acm_certificate.this.domain_validation_options
}
