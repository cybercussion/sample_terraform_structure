terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
  }

  backend "s3" {}
}

# General things to consider beyond this
# - Scale on request count, latency?
# - ECS Exec?
# - Support other platform versions than LATEST
# - Support EFS?
# - Logging/Metric Enhancements (Task def has basic)
# - Deployment Controller?


# Fetch VPC and Subnet IDs from SSM
data "aws_ssm_parameter" "vpc_id" {
  name = var.vpc_ssm_path
}

data "aws_ssm_parameter" "subnet_1a" {
  name = var.subnet_ssm_paths[0]
}

data "aws_ssm_parameter" "subnet_1b" {
  name = var.subnet_ssm_paths[1]
}

# Service Discovery Configuration
resource "aws_service_discovery_service" "this" {
  count            = var.enable_service_discovery ? 1 : 0
  name             = var.service_name
  namespace_id     = var.service_discovery_namespace_id

  dns_config {
    dns_records {
      type = "A"
      ttl  = var.dns_ttl
    }
    namespace_id = var.service_discovery_namespace_id
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = var.tags
}

# ECS Service (Fargate)
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  lifecycle {
    ignore_changes = [
      task_definition,
      network_configuration,
    ]
  }

  dynamic "deployment_controller" {
    for_each = var.deployment_type == "bluegreen" ? [1] : []
    content {
      type = "CODE_DEPLOY"
    }
  }

  network_configuration {
    subnets         = [data.aws_ssm_parameter.subnet_1a.value, data.aws_ssm_parameter.subnet_1b.value]
    security_groups = var.security_groups
    assign_public_ip = true
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn   = aws_service_discovery_service.this.arn
      container_name = var.service_name
      container_port = var.container_port
    }
  }

  load_balancer {
    target_group_arn = var.deployment_type == "rolling" ? var.blue_target_group_arn : var.green_target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  tags = var.tags
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU Auto Scaling Policy
resource "aws_appautoscaling_policy" "cpu_policy" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.service_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value        = var.cpu_target_value
    scale_in_cooldown   = var.scale_in_cooldown
    scale_out_cooldown  = var.scale_out_cooldown
  }
}

# Memory Auto Scaling Policy
resource "aws_appautoscaling_policy" "memory_policy" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.service_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value        = var.memory_target_value
    scale_in_cooldown   = var.scale_in_cooldown
    scale_out_cooldown  = var.scale_out_cooldown
  }
}

# CloudWatch Metric Alarms for CPU and Memory
resource "aws_cloudwatch_metric_alarm" "cpu_scaling" {
  count               = var.enable_autoscaling ? 1 : 0
  alarm_name          = "${var.service_name}-cpu-scaling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_target_value
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.cpu_policy[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_scaling" {
  count               = var.enable_autoscaling ? 1 : 0
  alarm_name          = "${var.service_name}-memory-scaling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.memory_target_value
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.memory_policy[0].arn]
}


# Scheduled Scaling Actions for ECS Console Visibility
resource "aws_appautoscaling_scheduled_action" "scale_up" {
  count              = var.enable_scheduled_scaling ? 1 : 0
  name               = "${var.service_name}-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = var.scheduled_scale_up_cron
  scalable_target_action {
    min_capacity = var.scheduled_scale_up_min_capacity
    max_capacity = var.scheduled_scale_up_min_capacity  # Assuming you want to set both to the same value for scale up
  }
}

resource "aws_appautoscaling_scheduled_action" "scale_down" {
  count              = var.enable_scheduled_scaling ? 1 : 0
  name               = "${var.service_name}-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = var.scheduled_scale_down_cron
  scalable_target_action {
    min_capacity = var.scheduled_scale_down_min_capacity
    max_capacity = var.scheduled_scale_down_min_capacity  # Assuming you want to set both to the same value for scale down
  }
}

# EventBridge Rule for Scheduled Scale-Up
resource "aws_cloudwatch_event_rule" "scale_up" {
  count               = var.enable_scheduled_scaling ? 1 : 0
  name                = "${var.service_name}-scale-up-schedule"
  schedule_expression = var.scheduled_scale_up_cron
}

# EventBridge Target for Scheduled Scale-Up
resource "aws_cloudwatch_event_target" "scale_up" {
  count     = var.enable_scheduled_scaling ? 1 : 0
  rule      = aws_cloudwatch_event_rule.scale_up[0].name
  target_id = "${var.service_name}-scale-up"
  arn       = var.cluster_arn
  role_arn  = var.codedeploy_service_role_arn

  ecs_target {
    task_count          = var.scheduled_scale_up_min_capacity
    task_definition_arn = var.task_definition_arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    network_configuration {
      subnets          = [data.aws_ssm_parameter.subnet_1a.value, data.aws_ssm_parameter.subnet_1b.value]
      security_groups  = var.security_groups
      assign_public_ip = true
    }
  }
}

# EventBridge Rule for Scheduled Scale-Down
resource "aws_cloudwatch_event_rule" "scale_down" {
  count               = var.enable_scheduled_scaling ? 1 : 0
  name                = "${var.service_name}-scale-down-schedule"
  schedule_expression = var.scheduled_scale_down_cron
}

# EventBridge Target for Scheduled Scale-Down
resource "aws_cloudwatch_event_target" "scale_down" {
  count     = var.enable_scheduled_scaling ? 1 : 0
  rule      = aws_cloudwatch_event_rule.scale_down[0].name
  target_id = "${var.service_name}-scale-down"
  arn       = var.cluster_arn
  role_arn  = var.codedeploy_service_role_arn

  ecs_target {
    task_count          = var.scheduled_scale_down_min_capacity
    task_definition_arn = var.task_definition_arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    network_configuration {
      subnets          = [data.aws_ssm_parameter.subnet_1a.value, data.aws_ssm_parameter.subnet_1b.value]
      security_groups  = var.security_groups
      assign_public_ip = true
    }
  }
}