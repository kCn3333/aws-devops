# ECS Fargate

## Overview

Deployed `clients-api` Spring Boot application on ECS Fargate behind ALB.
RDS credentials injected from Secrets Manager. Zero Ansible required — container has everything baked in.

## Result

```
https://devops.kcn333.com/swagger-ui/index.html  ✅ Swagger UI live
https://devops.kcn333.com/api/clients            401 Unauthorized (Spring Security working)
curl -u user:user .../api/clients                ✅ Returns 20 clients from PostgreSQL

ECS Task: kcn333/clients-api:latest (256 CPU / 512 MB Fargate)
Logs:     CloudWatch /ecs/aws-devops-dev-app
```

## Module Structure

```
terraform/modules/ecs/
├── main.tf       # cluster, log group, IAM roles, SG, task definition, service
├── variables.tf  # image, port, cpu/mem, subnet_ids, alb/rds integration
└── outputs.tf    # cluster_id, service_name, security_group_id, log_group_name
```

## Key Patterns

### Secrets injected from Secrets Manager
```hcl
secrets = [
  {
    name      = "DB_USERNAME"
    valueFrom = "${var.rds_secret_arn}:username::"  # format: arn:key::
  },
  {
    name      = "DB_PASSWORD"
    valueFrom = "${var.rds_secret_arn}:password::"
  }
]
```
ECS agent reads specific JSON keys from the secret and injects as env vars.
Container never sees the full secret — only what it needs.

### Two IAM roles
```hcl
# Task Execution Role — used by ECS agent
# Permissions: pull image, write CloudWatch logs, read Secrets Manager
resource "aws_iam_role" "task_execution" { ... }
resource "aws_iam_role_policy_attachment" "task_execution_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role — used by the running container
# Permissions: whatever the app needs (S3, SQS, etc.)
resource "aws_iam_role" "task" { ... }
```

### lifecycle ignore_changes for CI/CD coexistence
```hcl
lifecycle {
  ignore_changes = [task_definition, desired_count]
}
```
CI/CD creates new task definition revisions on each deploy.
Without this — terraform apply would revert to the Terraform-managed revision.

### Rolling deployment (zero downtime)
```hcl
deployment_minimum_healthy_percent = 100  # always keep current tasks healthy
deployment_maximum_percent         = 200  # allow 2x tasks during deployment
```

### target_type = "ip" for Fargate
```hcl
# EC2 → "instance" (registered by Instance ID)
# Fargate → "ip" (registered by container IP, awsvpc network mode)
target_type = "ip"
```

## Why Public Subnet for Fargate?

```
No NAT Gateway in our VPC (cost: ~$32/month)
    → Fargate in private subnet can't reach Docker Hub
    → Solution: public subnet + assign_public_ip = true
    → Security group still restricts inbound to ALB only

Production approach: ECR + VPC Endpoints + private subnet
```

## Spring Boot Startup Timing

```hcl
health_check_start_period = 90  # Spring Boot takes ~60s to start
# Without this grace period → health checks fail before app is ready
# → ECS keeps killing and restarting tasks in a loop
```

## IAM Non-ASCII Bug

IAM role/policy descriptions must be ASCII only.
Em-dash (—) in descriptions causes `ValidationError`.

```bash
# Find and fix all em-dashes in terraform files
find terraform/ -name "*.tf" -exec sed -i 's/—/-/g' {} +
```

## Verified Deployment

```bash
# Check service health
aws ecs describe-services \
  --cluster aws-devops-dev-cluster \
  --services aws-devops-dev-service \
  --region eu-north-1 \
  --query 'services[0].{running:runningCount,desired:desiredCount}'

# Stream live logs
aws logs tail /ecs/aws-devops-dev-app --follow --region eu-north-1

# Test API with auth
curl -u user:user https://devops.kcn333.com/api/clients | jq .
```

## Common Mistakes

- Non-ASCII characters (em-dash) in IAM descriptions → ValidationError
- Wrong `target_type` (instance vs ip) → tasks never register in target group
- Missing `startPeriod` on health check → Spring Boot killed before startup completes
- Fargate in private subnet without NAT → can't pull Docker Hub image → task fails
- Missing `secretsmanager:GetSecretValue` on task execution role → container start fails

---
