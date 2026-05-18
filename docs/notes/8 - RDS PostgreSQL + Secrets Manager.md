# RDS PostgreSQL + Secrets Manager

## Overview

Deployed PostgreSQL 17 in private subnets with credentials managed by
AWS Secrets Manager. Zero hardcoded passwords anywhere in code or config.

## Result

```
RDS Endpoint:  aws-devops-dev-db.c3iucycekr7z.eu-north-1.rds.amazonaws.com
Private IP:    10.0.20.225 (private subnet — no public access)
Engine:        PostgreSQL 17 / db.t3.micro / 20GB gp2 encrypted
Connection:    TLSv1.3 AES_256_GCM_SHA384 (in transit + at rest)

Secret:  aws-devops/dev/rds
  { username, password, host, port, dbname, url (JDBC) }
```

## Module Structure

```
terraform/modules/rds/
├── main.tf       # random_password, Secrets Manager, SG, subnet group, RDS
├── variables.tf  # project_name, env, vpc_id, subnet_ids, allowed_sgs, db config
└── outputs.tf    # endpoint, port, db_name, secret_arn, security_group_id
```

## Key Patterns

### Random password stored in Secrets Manager
```hcl
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}|;:,.<>?"  # RDS rejects: @, /, "
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
    url      = "jdbc:postgresql://${host}:${port}/${dbname}"
  })
}
```

### for_each fails with unknown values — use count instead
```hcl
# ❌ for_each with apply-time values as keys → plan error
for_each = toset(var.allowed_security_group_ids)

# ✅ count — length known at plan, values resolved at apply
resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  count                        = length(var.allowed_security_group_ids)
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}
```

### Production vs dev settings
```hcl
# Dev (current)
skip_final_snapshot = true    # destroy without snapshot
deletion_protection = false   # can be deleted
multi_az            = false   # single AZ (lower cost)
recovery_window     = 0       # immediate secret deletion

# Production (change these)
skip_final_snapshot = false   # always snapshot before destroy
deletion_protection = true    # requires manual disable before destroy
multi_az            = true    # standby replica, automatic failover
recovery_window     = 7       # 7 days to recover deleted secret
```

## Security

| Control | Setting | Reason |
|---------|---------|--------|
| `publicly_accessible` | false | No public IP — VPC only |
| `storage_encrypted` | true | KMS encryption at rest |
| TLS in transit | TLSv1.3 (enforced by RDS 14+) | Encrypted connection |
| SG access | EC2 SG only (port 5432) | No direct internet access |
| Credentials | Secrets Manager | No plaintext passwords in code |

## Bastion Host Access Pattern

RDS has no public IP — access only from within VPC:

```bash
# 1. SSH to EC2 (acts as bastion)
ssh -i ~/.ssh/aws-devops-key ubuntu@<EC2_PUBLIC_IP>

# 2. From EC2, retrieve credentials
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "aws-devops/dev/rds" --region eu-north-1 \
  --query SecretString --output text)
DB_HOST=$(echo $SECRET | jq -r '.host')
DB_PASS=$(echo $SECRET | jq -r '.password')

# 3. Connect to RDS
psql "postgresql://dbadmin:${DB_PASS}@${DB_HOST}:5432/clients_db"
```

## IAM Policy — EC2 reads secret

```hcl
resource "aws_iam_role_policy" "ec2_secrets" {
  name = "ec2-read-rds-secret"
  role = module.ec2.iam_role_name
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [module.rds.secret_arn]
    }]
  })
}
```

## Spring Boot Integration (Lesson 10)

The app's `application-prod.properties` uses:
```
spring.datasource.url=jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
```

ECS task will inject these from the Secrets Manager secret as env vars.

## Common Mistakes

- Special characters in SG descriptions (em-dash, etc.) → AWS rejects non-ASCII
- `for_each` with SG IDs from other resources → use `count` instead
- Connecting to RDS from local machine → it's in private subnet, only reachable from VPC
- Missing `jq` on EC2 → `sudo apt install -y jq` before parsing secrets

---
