# AWS DevOps Repo

Infrastructure as Code project learning production-grade AWS infrastructure 
provisioned with Terraform and configured with Ansible.

## Architecture

- **Cloud Provider:** AWS (eu-north-1 / Stockholm)
- **IaC:** Terraform >= 1.5
- **Configuration Management:** Ansible >= 2.15
- **CI/CD:** GitHub Actions

## Infrastructure Overview

| Component        | Technology         | Description                        |
|------------------|--------------------|------------------------------------|
| Networking       | Terraform + VPC    | Custom VPC, public/private subnets |
| Compute          | EC2 t3.micro       | Web servers with nginx             |
| Storage          | S3                 | Static assets + Terraform state    |
| IAM              | AWS IAM            | Least-privilege roles and policies |

## Repository Structure
├── terraform/
│   ├── modules/        # Reusable Terraform modules
│   ├── environments/   # Dev and prod configurations
│   └── global/         # Account-wide resources (IAM, S3 state)
├── ansible/
│   ├── inventory/      # Dynamic AWS inventory
│   ├── playbooks/      # Task playbooks
│   └── roles/          # Reusable Ansible roles
└── docs/notes/         # Learning notes

## Getting Started

### Prerequisites
- Terraform >= 1.5
- Ansible >= 2.15
- AWS CLI configured
- Python >= 3.10

### Usage
```bash
# Provision infrastructure
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Configure servers
cd ansible
ansible-playbook playbooks/site.yaml
```
