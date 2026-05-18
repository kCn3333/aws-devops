{
  "widgets": [
    {
      "type": "text",
      "x": 0, "y": 0, "width": 24, "height": 1,
      "properties": {
        "markdown": "## ${ecs_cluster_name} — Monitoring Dashboard"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 1, "width": 6, "height": 6,
      "properties": {
        "title": "ECS Running Tasks",
        "view": "singleValue",
        "region": "${region}",
        "period": 60,
        "annotations": {},
        "metrics": [[
          "ECS/ContainerInsights", "RunningTaskCount",
          "ClusterName", "${ecs_cluster_name}",
          "ServiceName", "${ecs_service_name}"
        ]]
      }
    },
    {
      "type": "metric",
      "x": 6, "y": 1, "width": 9, "height": 6,
      "properties": {
        "title": "ECS CPU Utilization",
        "view": "timeSeries",
        "region": "${region}",
        "period": 60,
        "annotations": {
          "horizontal": [{ "value": 80, "label": "80% warning", "color": "#ff7f0e" }]
        },
        "metrics": [[
          "ECS/ContainerInsights", "CpuUtilized",
          "ClusterName", "${ecs_cluster_name}",
          "ServiceName", "${ecs_service_name}",
          { "stat": "Average", "label": "CPU" }
        ]]
      }
    },
    {
      "type": "metric",
      "x": 15, "y": 1, "width": 9, "height": 6,
      "properties": {
        "title": "ECS Memory Utilization (MB)",
        "view": "timeSeries",
        "region": "${region}",
        "period": 60,
        "annotations": {
          "horizontal": [{ "value": ${memory_warning_mb}, "label": "80% of 512MB", "color": "#ff7f0e" }]
        },
        "metrics": [[
          "ECS/ContainerInsights", "MemoryUtilized",
          "ClusterName", "${ecs_cluster_name}",
          "ServiceName", "${ecs_service_name}",
          { "stat": "Average", "label": "Memory" }
        ]]
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 7, "width": 8, "height": 6,
      "properties": {
        "title": "ALB Request Count",
        "view": "timeSeries",
        "region": "${region}",
        "period": 60,
        "annotations": {},
        "metrics": [[
          "AWS/ApplicationELB", "RequestCount",
          "LoadBalancer", "${alb_arn_suffix}",
          { "stat": "Sum", "label": "Requests" }
        ]]
      }
    },
    {
      "type": "metric",
      "x": 8, "y": 7, "width": 8, "height": 6,
      "properties": {
        "title": "ALB Response Time (s)",
        "view": "timeSeries",
        "region": "${region}",
        "period": 60,
        "annotations": {},
        "metrics": [
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_arn_suffix}", { "stat": "p50", "label": "p50" }],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_arn_suffix}", { "stat": "p95", "label": "p95" }],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_arn_suffix}", { "stat": "p99", "label": "p99" }]
        ]
      }
    },
    {
      "type": "metric",
      "x": 16, "y": 7, "width": 8, "height": 6,
      "properties": {
        "title": "ALB 5xx Errors",
        "view": "timeSeries",
        "region": "${region}",
        "period": 60,
        "annotations": {},
        "metrics": [
          ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${alb_arn_suffix}", { "stat": "Sum", "label": "Target 5xx", "color": "#d62728" }],
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${alb_arn_suffix}", { "stat": "Sum", "label": "ELB 5xx", "color": "#ff7f0e" }]
        ]
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 13, "width": 12, "height": 6,
      "properties": {
        "title": "RDS CPU Utilization (%)",
        "view": "timeSeries",
        "region": "${region}",
        "period": 60,
        "annotations": {
          "horizontal": [{ "value": 80, "label": "80% warning", "color": "#ff7f0e" }]
        },
        "metrics": [[
          "AWS/RDS", "CPUUtilization",
          "DBInstanceIdentifier", "${rds_instance_id}",
          { "stat": "Average", "label": "CPU" }
        ]]
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 13, "width": 12, "height": 6,
      "properties": {
        "title": "RDS Free Storage (bytes)",
        "view": "timeSeries",
        "region": "${region}",
        "period": 300,
        "annotations": {
          "horizontal": [{ "value": 5368709120, "label": "5GB warning", "color": "#ff7f0e" }]
        },
        "metrics": [[
          "AWS/RDS", "FreeStorageSpace",
          "DBInstanceIdentifier", "${rds_instance_id}",
          { "stat": "Average", "label": "Free Storage" }
        ]]
      }
    }
  ]
}