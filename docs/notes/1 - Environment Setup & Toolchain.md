# Environment Setup & Toolchain

## Overview

Pre-requisites, tool installation, AWS account configuration, and core principles
required before writing any infrastructure code.

---

## Required Tools & Versions

| Tool        | Minimum Version | Purpose                              |
|-------------|----------------|--------------------------------------|
| AWS CLI     | >= 2.0         | Interact with AWS API from terminal  |
| Terraform   | >= 1.5.0       | Infrastructure provisioning (IaC)    |
| Ansible     | >= 2.15.0      | Server configuration management      |
| Python      | >= 3.10        | Required by Ansible                  |
| Git         | >= 2.38        | Version control                      |
| boto3       | latest         | AWS SDK for Python (Ansible AWS)     |

---

## Tool Roles

```
AWS          → cloud platform (compute, networking, storage)
Terraform    → provisions AWS resources (VPC, EC2, S3, IAM)
Ansible      → configures what Terraform created (packages, services, files)
Git          → single source of truth for all infrastructure code
```

**Terraform vs Ansible decision rule:**
- "Does this resource exist?" → Terraform
- "Is this server correctly configured?" → Ansible

---

## Installation Quickstart

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Terraform via tfenv (recommended — manages multiple versions)
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
tfenv install 1.9.0 && tfenv use 1.9.0

# Ansible + AWS dependencies
pip3 install ansible boto3 botocore
ansible-galaxy collection install amazon.aws

# Useful extras
sudo apt install jq tree        # JSON parser + directory tree
pip3 install pre-commit         # git hook manager
```

---

## AWS Account Setup

### Non-negotiable rules
1. **Never use root account** for day-to-day work — create an IAM user immediately
2. **Enable MFA** on root account
3. **Set a billing alarm** before doing anything else
4. **Never commit AWS credentials** to any repository

### IAM User Setup

```bash
aws iam create-user --user-name devops-admin
aws iam attach-user-policy \
  --user-name devops-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name devops-admin
# Save AccessKeyId and SecretAccessKey — shown ONCE only
```

### AWS CLI Configuration

```bash
aws configure
# Region: eu-north-1
# Output: json

# Verify
aws sts get-caller-identity
```

Credentials are stored in `~/.aws/credentials` — never commit this file.

### Billing Protection (Free Tier)

Set a zero-spend budget in AWS Console:
**Billing → Budgets → Create budget → Zero spend budget**

Free Tier key limits (12 months):
- EC2: 750h/month t2.micro or t3.micro
- S3: 5 GB storage
- RDS: 750h/month db.t2.micro
- DynamoDB: 25 GB (always free)

> AWS does not stop services when Free Tier is exceeded — it bills you.
> Always destroy unused resources: `terraform destroy`

---

## Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "you@email.com"
git config --global init.defaultBranch main
git config --global pull.rebase false

# SSH key for GitHub (ed25519 recommended)
ssh-keygen -t ed25519 -C "you@email.com" -f ~/.ssh/github_key
# Add public key to GitHub → Settings → SSH keys
```

---

## Environment Verification

```bash
echo -n "AWS CLI:   " && aws --version 2>&1 | head -1
echo -n "Terraform: " && terraform --version 2>&1 | head -1
echo -n "Ansible:   " && ansible --version 2>&1 | head -1
echo -n "Python:    " && python3 --version
echo -n "AWS Auth:  " && aws sts get-caller-identity --query 'Arn' --output text
```

---

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Git as source of truth** | Every infrastructure change goes through Git — no manual console edits |
| **No secrets in repo** | Keys, passwords, tokens → environment variables or AWS Secrets Manager |
| **Tag everything** | Every AWS resource needs `Environment`, `Project`, `ManagedBy` tags |
| **Isolated environments** | Dev and prod have separate state, separate configs |
| **Least privilege** | IAM roles get only the permissions they actually need |
| **Destroy when idle** | Free Tier has limits — `terraform destroy` is good practice |

---
