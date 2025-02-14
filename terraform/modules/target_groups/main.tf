terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

# Retrieve the VPC ID from SSM
data "aws_ssm_parameter" "vpc_id" {
  name = var.vpc_ssm_path
}


# Blue Target Group
resource "aws_lb_target_group" "blue" {
  name        = "${var.environment}-${var.service_name}-blue-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.environment}-${var.service_name}-blue-tg"
    }
  )
}

# Green Target Group
resource "aws_lb_target_group" "green" {
  #count = var.deployment_type != "rolling" ? 1 : 0
  count = contains(["bluegreen", "canary"], var.deployment_type) ? 1 : 0
  name        = "${var.environment}-${var.service_name}-green-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.environment}-${var.service_name}-green-tg"
    }
  )
}

# Root Path → Blue Target Group (Default for Rolling Updates)
resource "aws_lb_listener_rule" "root_http" {
  count        = var.enable_http ? 1 : 0
  listener_arn = var.http_listener_arn
  priority     = var.base_priority + 1

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  # Canary Deployment: Gradually shift traffic
  dynamic "action" {
    for_each = var.deployment_type == "canary" ? [1] : []
    content {
      type = "forward"
      forward {
        target_group {
          arn    = aws_lb_target_group.blue.arn
          weight = var.canary_traffic_weight
        }
        target_group {
          arn    = length(aws_lb_target_group.green) > 0 ? aws_lb_target_group.green[0].arn : aws_lb_target_group.blue.arn
          weight = 100 - var.canary_traffic_weight
        }
      }
    }
  }

  # Blue/Green Deployment: Switch entirely to Green
  dynamic "action" {
    for_each = var.deployment_type == "bluegreen" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = length(aws_lb_target_group.green) > 0 ? aws_lb_target_group.green[0].arn : aws_lb_target_group.blue.arn
    }
  }

  # Rolling Deployment: Always send traffic to Blue
  dynamic "action" {
    for_each = var.deployment_type == "rolling" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.blue.arn
    }
  }
}

# HTTPS Listener Rules
resource "aws_lb_listener_rule" "root_https" {
  # count        = var.manage_listener_rules ? 1 : 0
  listener_arn = var.https_listener_arn
  priority     = var.base_priority + 5

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  # Canary Deployment for HTTPS
  dynamic "action" {
    for_each = var.deployment_type == "canary" ? [1] : []
    content {
      type = "forward"
      forward {
        target_group {
          arn    = aws_lb_target_group.blue.arn
          weight = var.canary_traffic_weight
        }
        target_group {
          arn    = length(aws_lb_target_group.green) > 0 ? aws_lb_target_group.green[0].arn : aws_lb_target_group.blue.arn
          weight = 100 - var.canary_traffic_weight
        }
      }
    }
  }

  # Blue/Green Deployment: Switch entirely to Green
  dynamic "action" {
    for_each = var.deployment_type == "bluegreen" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = length(aws_lb_target_group.green) > 0 ? aws_lb_target_group.green[0].arn : aws_lb_target_group.blue.arn
    }
  }

  # Rolling Deployment: Always send traffic to Blue
  dynamic "action" {
    for_each = var.deployment_type == "rolling" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.blue.arn
    }
  }
}

# HTTP Listener Rules
# Route /blue* to Blue (Only if Rolling or Canary)
resource "aws_lb_listener_rule" "blue_http" {
  count        = var.enable_http && var.deployment_type != "bluegreen" ? 1 : 0
  listener_arn = var.http_listener_arn
  priority     = var.base_priority + 10

  condition {
    path_pattern {
      values = ["/blue*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  # lifecycle {
  #   ignore_changes = [action, priority]
  # }
}

# Route /green* to Green (Only if Canary or Blue/Green)
resource "aws_lb_listener_rule" "green_http" {
  count        = var.enable_http && var.deployment_type != "rolling" ? 1 : 0
  listener_arn = var.http_listener_arn
  priority     = var.base_priority + 20
  condition {
    path_pattern { values = ["/green*"] }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green[0].arn
  }
  # lifecycle {
  #   ignore_changes = [action, priority]
  # }
}

# HTTPS Listener Rules
resource "aws_lb_listener_rule" "blue_https" {
  count        = var.deployment_type != "bluegreen" ? 1 : 0
  listener_arn = var.https_listener_arn
  priority     = var.base_priority + 30

  condition {
    path_pattern {
      values = ["/blue*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_lb_listener_rule" "green_https" {
  count        = var.deployment_type != "rolling" ? 1 : 0
  listener_arn = var.https_listener_arn
  priority     = var.base_priority + 40
  condition {
    path_pattern { values = ["/green*"] }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green[0].arn
  }
}