# Repository Foundations & Terraform Remote State

## Overview

Established the foundational structure of the DevOps portfolio repository and configured
Terraform remote state using AWS S3 as a shared, secure backend.

---

## Key Concepts

### Infrastructure as Code (IaC)
Treat infrastructure like software — version it, review it, automate it.
Manual console clicks leave no history and cannot be reproduced reliably.

### Terraform State
Terraform tracks created resources in a `.tfstate` file.
- **Local state** — default, unsafe for teams (conflicts, plaintext secrets on disk)
- **Remote state** — stored in S3, shared across the team, encrypted at rest

### State Locking
Prevents two engineers from running `terraform apply` simultaneously.
Implemented via `use_lockfile = true` in the S3 backend (Terraform >= 1.10).
Creates a `.tflock` object in S3 during apply; removed on completion.

### Bootstrap Problem
Terraform cannot manage the S3 bucket that stores its own state.
Solution: one-time manual creation via `scripts/bootstrap-backend.sh`.

---

## Repository Structure

```
aws-devops-portfolio/
├── .github/workflows/          # CI/CD pipelines
├── terraform/
│   ├── modules/                # Reusable modules (vpc, ec2, s3)
│   ├── environments/dev|prod/  # Per-environment configuration
│   └── global/backend|iam/     # Account-wide shared resources
├── ansible/
│   ├── inventory/              # Static and dynamic inventory
│   ├── playbooks/
│   └── roles/
├── docs/notes/                 # Lesson notes (this file)
├── scripts/                    # Helper scripts
├── .gitignore
└── README.md
```

---

## Conventional Commits

```
<type>(<scope>): <imperative description>
```

| Type       | Use case                         |
|------------|----------------------------------|
| `feat`     | New feature                      |
| `fix`      | Bug fix                          |
| `docs`     | Documentation only               |
| `refactor` | Refactor without behaviour change |
| `chore`    | Maintenance (gitignore, deps)    |
| `ci`       | CI/CD pipeline changes           |

Rules: lowercase, imperative mood ("add" not "added"), no trailing period, max 72 chars.

---

## S3 Backend Configuration

```hcl
# terraform/environments/dev/backend.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket       = "kcn-terraform-state"
    key          = "environments/dev/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

S3 key structure allows one bucket for all environments:
```
kcn-terraform-state/
├── environments/dev/terraform.tfstate
├── environments/prod/terraform.tfstate
└── global/terraform.tfstate
```

---

## Provider Default Tags

```hcl
provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "aws-devops-portfolio"
      ManagedBy   = "terraform"
    }
  }
}
```

All resources created in this environment automatically inherit these tags.
Required for cost tracking (FinOps) and resource ownership visibility.

---

## Critical .gitignore Rules

| Pattern        | Reason                                      |
|----------------|---------------------------------------------|
| `*.tfstate`    | Contains plaintext secrets (passwords, keys)|
| `**/.terraform/` | Provider binaries, auto-generated locally |
| `*.tfvars`     | May contain environment secrets             |
| `*.tfvars.example` | **Commit this** — documents required vars |
| `.terraform.lock.hcl` | **Commit this** — pins provider versions |

> Add `.gitignore` as the very first commit. Files already tracked by Git
> are not affected by `.gitignore` — use `git rm --cached <file>` to untrack.

---

## Useful Commands

```bash
terraform init                  # initialise, download providers
terraform init -reconfigure     # use new backend config, keep existing state
terraform init -migrate-state   # use new backend config and migrate state
terraform fmt                   # format all .tf files
terraform validate              # validate syntax
terraform plan                  # preview changes
terraform apply                 # apply changes
```

---

## Common Mistakes to Avoid

- Committing `.tfstate` — always in `.gitignore`, always
- No state locking — race conditions in shared environments
- Hardcoded values — use variables and `tfvars`
- Missing tags — impossible to track costs or ownership later
- Manual console changes — undocumented, unreproducible

---
