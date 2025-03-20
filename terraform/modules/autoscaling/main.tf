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

# Define ECS Service scaling target
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale-up policy
resource "aws_appautoscaling_policy" "scale_up" {
  name                = "scale-up"
  policy_type         = "TargetTrackingScaling"
  resource_id         = aws_appautoscaling_target.this.resource_id
  scalable_dimension  = aws_appautoscaling_target.this.scalable_dimension
  service_namespace   = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.target_value
    predefined_metric_specification {
      predefined_metric_type = var.predefined_metric
    }
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# Scale-down policy
resource "aws_appautoscaling_policy" "scale_down" {
  name                = "scale-down"
  policy_type         = "TargetTrackingScaling"
  resource_id         = aws_appautoscaling_target.this.resource_id
  scalable_dimension  = aws_appautoscaling_target.this.scalable_dimension
  service_namespace   = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.scale_down_target_value
    predefined_metric_specification {
      predefined_metric_type = var.predefined_metric
    }
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}