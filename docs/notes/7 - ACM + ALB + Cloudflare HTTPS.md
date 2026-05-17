# ACM + ALB + Cloudflare HTTPS

## Overview

Deployed HTTPS on `devops.kcn333.com` using AWS ALB with ACM certificate,
automated DNS validation via Cloudflare Terraform provider.

## Result

```
https://devops.kcn333.com → HTTP/2 200  ✅ (ACM cert, TLS 1.3)
http://devops.kcn333.com  → 301 → HTTPS ✅ (permanent redirect)
Certificate validated in: ~14 seconds (Cloudflare fast propagation)
Resources created: 36
```

## Architecture

```
Internet → Cloudflare DNS (devops CNAME → ALB)
        → ALB SG (80, 443 open)
            ├── :80  → 301 redirect → HTTPS
            └── :443 → ACM cert → Target Group → EC2 :80 (nginx)
                         EC2 SG: ingress 80 from ALB SG only
```

## Modules Created

```
terraform/modules/acm/     # certificate + DNS validation outputs
terraform/modules/alb/     # ALB, listeners, target group, SG
```

## Key Patterns

### ACM DNS validation with Cloudflare provider
```hcl
# Two providers in one root module
required_providers {
  aws        = { source = "hashicorp/aws",        version = "~> 5.0" }
  cloudflare = { source = "cloudflare/cloudflare", version = "~> 4.0" }
}

# Auto-create validation CNAME in Cloudflare
resource "cloudflare_record" "acm_validation" {
  for_each = { for dvo in module.acm.domain_validation_options : dvo.domain_name => dvo }
  name    = trimsuffix(each.value.resource_record_name, ".")
  content = trimsuffix(each.value.resource_record_value, ".")
  type    = each.value.resource_record_type
  proxied = false  # MUST be false — Cloudflare cannot proxy ACM validation records
}

# Block apply until certificate is validated
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = [for r in cloudflare_record.acm_validation : r.hostname]
}

# ALB uses validated ARN — guarantees cert is valid before listener starts
module "alb" {
  certificate_arn = aws_acm_certificate_validation.this.certificate_arn
}
```

### HTTP → HTTPS redirect listener
```hcl
resource "aws_lb_listener" "http" {
  port     = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"  # permanent redirect
    }
  }
}
```

### Security group chaining — restrict EC2 to ALB only
```hcl
resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id            = module.ec2.security_group_id
  referenced_security_group_id = module.alb.security_group_id  # SG reference, not CIDR
  from_port                    = 80
  ip_protocol                  = "tcp"
}
```

### TLS policy — TLS 1.3 + 1.2, no weak ciphers
```hcl
resource "aws_lb_listener" "https" {
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}
```

## 502 Bad Gateway — Root Cause & Fix

```
Cause:  New EC2 instance (fresh terraform apply) had no nginx installed
        ALB health check → connection refused → all targets unhealthy → 502

Fix:    ansible-playbook playbooks/site.yaml
        (installs nginx → health check passes → 200)
```

**Key learning:** Terraform provisions infrastructure, Ansible configures it.
Every new EC2 requires Ansible run before it serves traffic.

## Cloudflare API Token

Required permissions (minimum):
- Zone → DNS → Edit
- Zone → Zone → Read
- Scope: Specific zone (kcn333.com) — not full account

## ACM Auto-Renewal

ACM automatically renews certificates. The DNS validation CNAME must remain
in Cloudflare permanently — ACM checks it on each renewal (~60 days before expiry).

## Common Mistakes

- `proxied = true` on ACM validation record — Cloudflare intercepts the CNAME check → validation never completes
- Referencing `module.acm.certificate_arn` in ALB instead of `aws_acm_certificate_validation.this.certificate_arn` — ALB starts with unvalidated cert
- Forgetting to run Ansible after terraform apply creates new EC2 → 502

---
