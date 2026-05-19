# CloudWatch Monitoring

## Overview

Production-grade monitoring with CloudWatch alarms, SNS email notifications,
and a multi-service dashboard covering ECS, ALB, and RDS metrics.

## What Was Built

```
7 CloudWatch Alarms
  CRITICAL: ECS task count = 0, ALB no healthy hosts
  WARNING:  ECS CPU/memory high, ALB 5xx errors, RDS CPU/storage

1 CloudWatch Dashboard
  Row 1: ECS (running tasks, CPU, memory)
  Row 2: ALB (request count, p50/p95/p99 latency, 5xx errors)
  Row 3: RDS (CPU, free storage)

1 SNS Topic → email notifications on alarm state changes
```

## Module Structure

```
terraform/modules/monitoring/
├── main.tf              # SNS topic, 7 alarms, CloudWatch dashboard
├── variables.tf         # project, env, ecs/alb/rds identifiers, alarm_email
├── outputs.tf           # sns_topic_arn, dashboard_url
└── dashboard.json.tpl   # JSON template for dashboard widgets
```

## Key Patterns

### Alarm configuration
```hcl
resource "aws_cloudwatch_metric_alarm" "ecs_task_count_zero" {
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1      # immediate for CRITICAL
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"   # no data = ALARM for CRITICAL
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
}
```

### treat_missing_data decision
```
"breaching"    → CRITICAL alarms (task count, healthy hosts)
                 No data = assume worst case = trigger alarm
"notBreaching" → WARNING alarms (CPU, memory, errors)
                 No data during startup = don't trigger false alarms
```

### evaluation_periods — noise filtering
```
= 1 → alarm immediately on first breach  (CRITICAL: service down)
= 3 → alarm only after 3 consecutive breaches (WARNING: CPU spike vs sustained high)
```

### templatefile() for dashboard JSON
```hcl
dashboard_body = templatefile("${path.module}/dashboard.json.tpl", {
  region           = var.aws_region
  ecs_cluster_name = var.ecs_cluster_name
  alb_arn_suffix   = var.alb_arn_suffix
  rds_instance_id  = var.rds_instance_id
})
```

Every metric widget requires `"region"` field — missing it causes 400 error.

### Percentile metrics for latency
```json
["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "...", { "stat": "p50" }],
["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "...", { "stat": "p95" }],
["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "...", { "stat": "p99" }]
```
Average hides tail latency. p99 = worst experience for 1% of users.

## CloudWatch Namespaces Used

| Service | Namespace | Key Metrics |
|---------|-----------|-------------|
| ECS | ECS/ContainerInsights | RunningTaskCount, CpuUtilized, MemoryUtilized |
| ALB | AWS/ApplicationELB | RequestCount, TargetResponseTime, HTTPCode_Target_5XX_Count, HealthyHostCount |
| RDS | AWS/RDS | CPUUtilization, FreeStorageSpace, DatabaseConnections |

## SNS Email Subscription

After `terraform apply`, AWS sends a confirmation email.
**Must click the confirmation link** or notifications won't be delivered.

## Bugs Fixed

### Dashboard 400 error — missing region
```json
Every metric widget properties block must include:
"region": "eu-north-1"
"annotations": {}  (required by some widget types)
```

### HCL semicolons in jsonencode() block
```
HCL does not support semicolons to separate attributes on one line.
Fix: use templatefile() with a .json.tpl file instead of jsonencode() for large JSON.
```

## Common Mistakes

- Missing `region` field in dashboard widget → 400 InvalidParameterInput
- Forgetting to click SNS subscription confirmation email
- `treat_missing_data = "breaching"` on WARNING alarms → false alarms during cold start
- Using Average for latency → hides tail latency issues
- Not enabling Container Insights on ECS cluster → ECS metrics unavailable

---
