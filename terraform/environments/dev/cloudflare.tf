# -----------------------------------------------------------------------------
# Cloudflare Provider
# -----------------------------------------------------------------------------
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# -----------------------------------------------------------------------------
# ACM DNS Validation Records
# Creates CNAME records in Cloudflare so AWS can verify domain ownership
# -----------------------------------------------------------------------------
resource "cloudflare_record" "acm_validation" {
  for_each = {
    for dvo in module.acm.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
      type  = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = trimsuffix(each.value.name, ".") # AWS adds trailing dot - remove it
  content = trimsuffix(each.value.value, ".")
  type    = each.value.type
  ttl     = 60
  proxied = false # MUST be false for ACM validation - Cloudflare cannot proxy DNS records
}

# -----------------------------------------------------------------------------
# Wait for ACM certificate to be validated
# -----------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = [for record in cloudflare_record.acm_validation : record.hostname]
}

# -----------------------------------------------------------------------------
# CNAME: devops.kcn333.com → ALB DNS name
# -----------------------------------------------------------------------------
resource "cloudflare_record" "devops" {
  zone_id = var.cloudflare_zone_id
  name    = "devops"
  content = module.alb.dns_name
  type    = "CNAME"
  ttl     = 60
  proxied = false
}
