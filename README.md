# AWS DevOps Repo

Infrastructure as Code project learning production-grade AWS infrastructure 
provisioned with Terraform and configured with Ansible, featuring a fully automated CI/CD pipeline via GitHub Actions.

## Architecture

```bash
                     Internet
                         │
                  ┌──────▼──────┐
                  │     IGW     │
                  └──────┬──────┘
                         │
     ┌───────────────────▼────────────────────┐
     │           VPC  10.0.0.0/16             │
     │           eu-north-1 (Stockholm)       │
     │                                        │
     │  ┌──────────────┐  ┌──────────────┐    │
     │  │Public Subnet │  │Public Subnet │    │
     │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │    │
     │  │  eu-north-1a │  │  eu-north-1b │    │
     │  │              │  │              │    │
     │  │  ┌────────┐  │  │              │    │
     │  │  │  EC2   │  │  │              │    │
     │  │  │t3.micro│  │  │              │    │
     │  │  │ nginx  │  │  │              │    │
     │  │  └────────┘  │  │              │    │
     │  └──────────────┘  └──────────────┘    │
     │  ┌──────────────┐  ┌──────────────┐    │
     │  │Priv. Subnet  │  │Priv. Subnet  │    │
     │  │ 10.0.10.0/24 │  │ 10.0.20.0/24 │    │
     │  └──────────────┘  └──────────────┘    │
     └────────────────────────────────────────┘
                         │
          ┌──────────────▼──────────────┐
          │       S3: Terraform State   │
          │       kcn-terraform-state   │
          └─────────────────────────────┘
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Cloud | AWS (eu-north-1) | Cloud platform |
| Network | VPC, Subnets, IGW | Isolated network — 2 AZs |
| Compute | EC2 t3.micro, Ubuntu 24.04 | Web server |
| IaC | Terraform >= 1.10 | Infrastructure provisioning |
| Config | Ansible >= 2.15 | Server configuration |
| CI/CD | GitHub Actions + OIDC | Automated pipeline |
| State | S3 + lockfile | Remote, encrypted, locked |

## CI/CD Pipeline

Every Pull Request triggers automatically:

```bash
PR opened
├── Terraform: fmt check → validate → plan (posted as PR comment)
└── Ansible:   ansible-lint (production profile)
```

Authentication via **OIDC** — no long-lived AWS credentials stored anywhere.

## Repository Structure

```bash
├── .github/workflows/
│   ├── terraform.yaml      # fmt, validate, plan on PRs
│   └── ansible.yaml        # ansible-lint on PRs
├── terraform/
│   ├── modules/
│   │   ├── vpc/            # VPC, subnets, IGW, route tables
│   │   └── ec2/            # EC2, security group, IAM, key pair
│   ├── environments/dev/   # dev environment configuration
│   └── global/iam/         # OIDC provider, GitHub Actions IAM role
├── ansible/
│   ├── inventory/          # dynamic AWS + static CI inventory
│   ├── playbooks/          # site.yaml entry point
│   └── roles/
│       ├── common/         # system updates, base packages
│       └── nginx/          # nginx install, config, index page
├── scripts/
│   └── bootstrap-backend.sh
└── docs/notes/             # lesson notes
```

## Prerequisites

```bash
terraform >= 1.10
ansible   >= 2.15
python    >= 3.10
aws-cli   >= 2.0
boto3, botocore
ansible-galaxy collection install amazon.aws community.general
```

## Quick Start

### 1. Bootstrap (one-time)
```bash
# Create S3 state bucket
bash scripts/bootstrap-backend.sh kcn-terraform-state

# Create OIDC role for GitHub Actions
cd terraform/global/iam
terraform init && terraform apply
```

### 2. Provision infrastructure
```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — add your SSH public key

terraform init
terraform plan
terraform apply
```

### 3. Configure servers
```bash
cd ansible
ansible-playbook playbooks/site.yaml
```

### 4. Verify
```bash
# SSH access
ssh -i ~/.ssh/aws-devops-key ubuntu@$(cd terraform/environments/dev && terraform output -raw instance_public_ip)

# Web server
curl http://$(cd terraform/environments/dev && terraform output -raw instance_public_ip)
```

## Security Highlights

- **OIDC authentication** — GitHub Actions assumes IAM role, no stored credentials
- **IMDSv2 enforced** — protects against SSRF attacks on EC2 metadata
- **Encrypted EBS** — root volume encrypted at rest
- **Remote state** — encrypted S3 backend with state locking
- **Least privilege** — dedicated IAM roles per service