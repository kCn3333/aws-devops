# Terraform EC2 Module

## Overview

Built a reusable EC2 module deploying a hardened Ubuntu 24.04 web server
into the VPC created in Lesson 03, with Security Groups, IAM Instance Profile,
and security best practices enforced via code.

## What Was Built

```
Public Subnet (10.0.1.0/24)
└── EC2 t3.micro — Ubuntu 24.04 LTS
    ├── Security Group: ingress 22, 80, 443 / egress all
    ├── IAM Instance Profile — SSM policy (keyless access)
    ├── EBS gp3 20GB encrypted
    └── IMDSv2 enforced
```

Resources created: Key Pair, Security Group (+ 4 rules), IAM Role,
IAM Policy Attachment, IAM Instance Profile, EC2 Instance. Total: 10.

## Module Structure

```
terraform/modules/ec2/
├── main.tf       # AMI data source, SG, IAM, instance
├── variables.tf  # inputs
└── outputs.tf    # instance_id, public_ip, public_dns, sg_id
```

## Key Patterns

### Dynamic AMI lookup — never hardcode AMI IDs
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu official account)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
```

### Separate SG rules (not inline — deprecated in provider 5.x)
```hcl
resource "aws_security_group" "this" { ... }

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.this.id
  from_port = 22
  to_port   = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidrs[0]
}
```

### IAM policy document in HCL (not raw JSON)
```hcl
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
```

### Security best practices in instance config
```hcl
resource "aws_instance" "this" {
  ...
  root_block_device {
    volume_type = "gp3"    # newer, cheaper than gp2
    encrypted   = true     # encrypt at rest
  }
  metadata_options {
    http_tokens = "required"  # enforce IMDSv2 — prevents SSRF credential theft
  }
}
```

### Chaining module outputs as inputs
```hcl
module "ec2" {
  vpc_id    = module.vpc.vpc_id                 # VPC output → EC2 input
  subnet_id = module.vpc.public_subnet_ids[0]   # VPC output → EC2 input
}
```

## Security Decisions

| Control | Setting | Reason |
|---------|---------|--------|
| IMDSv2 | `http_tokens = required` | Prevents SSRF attacks stealing IAM credentials |
| EBS encryption | `encrypted = true` | Protects data if volume is detached |
| IAM Instance Profile | SSM policy | No hardcoded credentials needed |
| SG ingress | Only 22, 80, 443 | Minimal exposure |

**Production improvement:** replace `0.0.0.0/0` SSH with your IP/32,
or remove port 22 entirely and use SSM Session Manager.

## Outputs

```
instance_id         = "i-0b252dbddc41454a2"
instance_public_ip  = "51.21.254.216"
instance_public_dns = "ec2-51-21-254-216.eu-north-1.compute.amazonaws.com"
ssh_command         = "ssh -i ~/.ssh/aws-devops-key ubuntu@51.21.254.216"
vpc_id              = "vpc-0898ffef7378885a9"
```

## Verified

```bash
$ ssh -i ~/.ssh/aws-devops-key ubuntu@51.21.254.216
ubuntu@ip-10-0-1-147:~$ uname -a
Linux ip-10-0-1-147 6.17.0-1013-aws ... Ubuntu 24.04 x86_64
```

## Common Mistakes

- Hardcoded AMI IDs — breaks after each Ubuntu patch release
- Inline SG rules — deprecated, causes full SG replacement on rule changes
- No IAM Instance Profile — forces hardcoded credentials anti-pattern
- IMDSv1 — vulnerable to SSRF attacks
- `gp2` volumes — more expensive, lower baseline performance than `gp3`

---
