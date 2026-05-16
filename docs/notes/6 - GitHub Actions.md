# GitHub Actions CI/CD

## Overview

Implemented a production-grade CI/CD pipeline using GitHub Actions with OIDC
authentication — no long-lived AWS credentials stored anywhere.

## What Was Built

```
Pull Request opened
       │
       ├── Terraform CI
       │     ├── fmt -check      (formatting gate)
       │     ├── validate        (syntax gate)
       │     └── plan            (posted as PR comment)
       │
       └── Ansible CI
             └── ansible-lint    (production profile)
```

## OIDC Authentication Flow

```
GitHub Actions Job
    → presents JWT token to AWS
    → AWS verifies against GitHub's JWKS endpoint
    → AWS issues temporary credentials (15 min TTL)
    → job runs terraform plan/apply
    → credentials expire automatically on job end
```

Zero long-lived secrets. No rotation required.

## IAM OIDC Setup (Terraform)

```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Allow only our specific repo to assume the role
condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"
  values   = ["repo:kCn3333/aws-devops:*"]
}
```

## Workflow Key Patterns

### Minimal permissions
```yaml
permissions:
  id-token: write      # required for OIDC token request
  contents: read
  pull-requests: write # required to post plan as PR comment
```

### paths filter — don't run on unrelated changes
```yaml
on:
  pull_request:
    paths:
      - "terraform/**"   # only run when terraform files change
```

### Job dependencies
```yaml
jobs:
  lint:     # runs first
  validate:
    needs: lint       # runs only if lint passes
  plan:
    needs: validate   # runs only if validate passes
```

### Sensitive variables in CI
```hcl
# Never use file() in Terraform — path doesn't exist on runner
# ❌ public_key = file("~/.ssh/key.pub")
# ✅ public_key = var.ec2_public_key
variable "ec2_public_key" {
  type      = string
  sensitive = true
}
```
```yaml
# In workflow — TF_VAR_* maps to Terraform variable
env:
  TF_VAR_ec2_public_key: ${{ secrets.EC2_PUBLIC_KEY }}
```

## GitHub Secrets Required

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN` | `arn:aws:iam::ACCOUNT_ID:role/github-actions-role` |
| `AWS_REGION` | `eu-north-1` |
| `EC2_PUBLIC_KEY` | Contents of `~/.ssh/aws-devops-key.pub` |

## Bugs Fixed

### `use_lockfile is not expected here`
```
Cause:   use_lockfile requires Terraform >= 1.10.0
Fix:     terraform_version: "~1.10" in workflow (was ~1.9)
```

### `No module named 'ansible_collections.amazon'`
```
Cause:   GitHub Actions runner is a clean environment — no collections
Fix:     ansible-galaxy collection install amazon.aws community.general
```

### `yaml[trailing-spaces]` / `yaml[new-line-at-end-of-file]`
```
Cause:   Editor leaving trailing whitespace, missing final newline
Fix:     sed -i 's/[[:space:]]*$//' file.yaml
Config:  VSCode: "files.trimTrailingWhitespace": true
```

### Static inventory for CI
```
Cause:   ansible-lint runs --syntax-check which loads dynamic AWS inventory
         Dynamic inventory requires boto3 + AWS credentials on runner
Fix:     Create ansible/inventory/ci_hosts with localhost
         Set ANSIBLE_INVENTORY=inventory/ci_hosts in workflow env
```

## ansible-lint Production Profile

```yaml
# .ansible-lint
profile: production
exclude_paths:
  - playbooks/archive/
warn_list:
  - yaml[truthy]
  - name[casing]
```

`production` enforces: FQCN module names, no trailing spaces,
newlines at EOF, proper task naming conventions.

## Common Mistakes

- Using `file()` for paths that don't exist on CI runners
- Storing long-lived AWS credentials in GitHub Secrets
- Missing `permissions: id-token: write` for OIDC
- Not pinning Terraform version — `~1.9` vs `~1.10` breaks `use_lockfile`
- Forgetting that CI runner is a clean environment — install all dependencies

---
