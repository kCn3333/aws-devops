# Conditional ECS Rolling Deploy

## Overview

Added ECS deployment job to clients-api CI pipeline.
Conditionally deploys only when AWS infrastructure is running.

## Flow

```
git push → main
  test → build-and-push → deploy-to-aws
                               │
                     check ECS service status
                               │
                    ACTIVE  → rolling deploy → wait stable
                    NOTFOUND → skip gracefully
```

## Key Pattern — Conditional Deploy

```yaml
- name: Check ECS service status
  id: check_ecs
  run: |
    STATUS=$(aws ecs describe-services \
      --cluster aws-devops-dev-cluster \
      --services aws-devops-dev-service \
      --query 'services[0].status' \
      --output text 2>/dev/null || echo "NOTFOUND")
    echo "status=$STATUS" >> $GITHUB_OUTPUT

- name: Deploy to ECS
  if: steps.check_ecs.outputs.status == 'ACTIVE'
  run: |
    aws ecs update-service \
      --cluster aws-devops-dev-cluster \
      --service aws-devops-dev-service \
      --force-new-deployment --region eu-north-1

- name: Wait for stability
  if: steps.check_ecs.outputs.status == 'ACTIVE'
  run: |
    aws ecs wait services-stable \
      --cluster aws-devops-dev-cluster \
      --services aws-devops-dev-service --region eu-north-1
```

## OIDC Multi-Repo Trust

```hcl
# One IAM role trusted by multiple repos
values = [
  "repo:kCn3333/aws-devops:*",
  "repo:kCn3333/clients-api:*"
]
```

## Three Scenarios

| Infrastructure | Push to main result |
|---------------|-------------------|
| Running (ACTIVE) | test → build → deploy → live |
| Destroyed (NOTFOUND) | test → build → skip (no error, no cost) |
| Reprovisioned | ECS pulls :latest automatically |

## Debugging OIDC Failures

```bash
# Check trust policy
aws iam get-role --role-name github-actions-role \
  --query 'Role.AssumeRolePolicyDocument' | jq .

# Symptom: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
# Cause: global/iam not applied after code change or role was destroyed
# Fix: cd terraform/global/iam && terraform apply
```

## force-new-deployment vs SHA Tags

| Approach | Use case | Rollback |
|----------|----------|---------|
| `force-new-deployment` + `:latest` | Dev/learning | Re-push old image |
| New task definition + SHA tag | Production | `update-service --task-definition family:PREV` |

## Common Mistakes

- Forgetting `permissions: id-token: write` on the deploy job
- Not running `terraform apply` in global/iam after adding new repo to OIDC
- No `aws ecs wait` → pipeline succeeds but deploy may have failed
- Using `force-new-deployment` without `:latest` tag → pulls same old image