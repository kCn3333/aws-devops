# AWS DevOps
![Terraform CI](https://github.com/kCn3333/aws-devops/actions/workflows/terraform.yaml/badge.svg)
![Ansible CI](https://github.com/kCn3333/aws-devops/actions/workflows/ansible.yaml/badge.svg)

Infrastructure as Code project learning production-grade AWS infrastructure 
provisioned with Terraform and configured with Ansible, featuring a fully automated CI/CD pipeline via GitHub Actions with OIDC authentication.

---

## Architecture
                        Internet
                            │
                ┌───────────▼───────────┐
                │   Cloudflare DNS      │
                │  devops.kcn333.com    │
                └───────────┬───────────┘
                            │ HTTPS (TLS 1.3)
                ┌───────────▼───────────┐
                │   AWS ALB             │
                │   ACM Certificate     │
                │   HTTP → HTTPS 301    │
                └───┬────────────────┬──┘
                    │                │
          ┌─────────▼───┐       ┌────▼────────┐
          │Public Subnet│       │Public Subnet│
          │ eu-north-1a │       │ eu-north-1b │
          │             │       │             │
          │ ECS Fargate │       │             │
          │ clients-api │       │             │
          │ :8080       │       │             │
          └─────────────┘       └─────────────┘
                    │
          ┌─────────▼───┐       ┌─────────────┐
          │Private Sub. │       │Private Sub. │
          │ eu-north-1a │       │ eu-north-1b │
          │             │       │             │
          │  RDS        │       │  RDS        │
          │  PostgreSQL │       │  Standby    │
          │  17         │       │  (Multi-AZ) │
          └─────────────┘       └─────────────┘
                    │
          ┌─────────▼────────────────────────┐
          │        AWS Services              │
          │  Secrets Manager  CloudWatch     │
          │  S3 (TF State)    SNS Alerts     │
          └──────────────────────────────────┘

---

## Tech Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Cloud** | AWS eu-north-1 | Stockholm region |
| **Network** | VPC + Subnets + IGW | 2 AZs, public + private |
| **TLS/DNS** | ACM + Cloudflare | TLS 1.3, auto-renewed cert |
| **Load Balancer** | AWS ALB | HTTP→HTTPS redirect, health checks |
| **Runtime** | ECS Fargate | Serverless containers, rolling deploy |
| **Application** | Spring Boot 3.5 | [clients-api](https://github.com/kCn3333/clients-api) |
| **Database** | RDS PostgreSQL 17 | Private subnet, encrypted, TLSv1.3 |
| **Secrets** | AWS Secrets Manager | Zero hardcoded credentials |
| **IaC** | Terraform >= 1.10 | Modular, remote S3 state with locking |
| **Config** | Ansible >= 2.15 | Roles, dynamic AWS inventory |
| **CI/CD** | GitHub Actions | OIDC auth, plan as PR comment |
| **Monitoring** | CloudWatch | Dashboard, 7 alarms, SNS email alerts |

---

## CI/CD Pipeline

```
Pull Request
├── terraform fmt -check  (formatting gate)
├── terraform validate    (syntax gate)
├── terraform plan        (posted as PR comment)
└── ansible-lint          (production profile)
Push to main (clients-api repo)
├── mvn test              (unit tests)
├── docker build + push   (Docker Hub)
└── ECS rolling deploy    (if infrastructure is running)
```

Authentication: **OIDC** — GitHub Actions assumes IAM role, zero stored credentials.

---

## Repository Structure

```bash
aws-devops/
├── .github/workflows/
│   ├── terraform.yaml        # fmt, validate, plan on PRs
│   └── ansible.yaml          # ansible-lint on PRs
├── terraform/
│   ├── modules/
│   │   ├── vpc/              # VPC, subnets, IGW, route tables
│   │   ├── ec2/              # EC2, security group, IAM, key pair
│   │   ├── acm/              # SSL certificate with DNS validation
│   │   ├── alb/              # Application Load Balancer + listeners
│   │   ├── rds/              # PostgreSQL, Secrets Manager
│   │   ├── ecs/              # ECS Fargate cluster + service
│   │   └── monitoring/       # CloudWatch alarms + dashboard + SNS
│   ├── environments/
│   │   └── dev/              # dev environment wiring all modules
│   └── global/
│       └── iam/              # OIDC provider + GitHub Actions IAM role
├── ansible/
│   ├── inventory/            # dynamic AWS EC2 + static CI inventory
│   ├── playbooks/            # site.yaml entry point
│   └── roles/
│       ├── common/           # system updates, base packages
│       └── nginx/            # nginx, Jinja2 config templates
├── scripts/
│   └── bootstrap-backend.sh  # one-time S3 state bucket setup
└── docs/notes/               # lesson notes (Terraform, Ansible, AWS)
```

---

## Security Highlights

| Control | Implementation |
|---------|---------------|
| **Zero stored credentials** | GitHub Actions uses OIDC — temporary 15min tokens |
| **Encrypted state** | Terraform state in S3 with AES256 encryption |
| **Encrypted database** | RDS storage encrypted, TLSv1.3 in transit |
| **Encrypted EBS** | EC2 root volume encrypted at rest |
| **IMDSv2** | EC2 metadata service v2 enforced (SSRF protection) |
| **Private database** | RDS in private subnet — no public IP |
| **Least privilege** | Separate IAM roles per service with minimal permissions |
| **Secret rotation ready** | Credentials in Secrets Manager, not in code |

---

## Prerequisites

```bash
terraform  >= 1.10
ansible    >= 2.15
python     >= 3.10
aws-cli    >= 2.0
jq                    # JSON parsing in scripts
boto3, botocore       # Ansible AWS inventory
ansible-galaxy collection install amazon.aws community.general
```

---

## Quick Start

### 1. Bootstrap (one-time per AWS account)

```bash
# Create S3 state bucket
bash scripts/bootstrap-backend.sh kcn-terraform-state

# Create OIDC IAM role for GitHub Actions
cd terraform/global/iam
cp terraform.tfvars.example terraform.tfvars
# Edit: set github_org and github_repo
terraform init && terraform apply
```

### 2. Configure secrets in GitHub
Settings → Secrets and variables → Actions:
AWS_ROLE_ARN     → arn:aws:iam::ACCOUNT:role/github-actions-role
AWS_REGION       → eu-north-1
EC2_PUBLIC_KEY   → contents of ~/.ssh/your-key.pub
ALARM_EMAIL      → your@email.com

### 3. Provision infrastructure

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit: set ec2_public_key, cloudflare_api_token, cloudflare_zone_id, alarm_email

terraform init
terraform plan
terraform apply
```

### 4. Configure EC2 (nginx)

```bash
cd ansible
ansible-playbook playbooks/site.yaml
```

### 5. Verify

```bash
# Infrastructure
curl -I https://devops.kcn333.com

# Application API
curl -u user:user https://devops.kcn333.com/api/clients

# Swagger UI
open https://devops.kcn333.com/swagger-ui/index.html
```

---

## Monitoring

| Resource | Location |
|---------|---------|
| CloudWatch Dashboard | AWS Console → CloudWatch → Dashboards → aws-devops-dev |
| Application Logs | AWS Console → CloudWatch → Log Groups → /ecs/aws-devops-dev-app |
| Alarms | AWS Console → CloudWatch → Alarms |

Alarms notify via SNS email on state changes (CRITICAL/WARNING thresholds).

---

## Cost Estimate (eu-north-1)

| Resource | Monthly Cost |
|----------|-------------|
| EC2 t3.micro | ~$0 (Free Tier) |
| RDS db.t3.micro | ~$0 (Free Tier) |
| ALB | ~$18 |
| ECS Fargate (256 CPU / 512MB) | ~$8 |
| Secrets Manager | ~$0.40 |
| CloudWatch | ~$2 |
| **Total** | **~$28/month** |

> Run `terraform destroy` when not in use to pause costs.

---