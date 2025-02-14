terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}
# With the write permissions log group this would get created via task def / task role
resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = 30
  tags              = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"  # Ensure network mode is "awsvpc" for Fargate
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  requires_compatibilities = ["FARGATE"]  # Ensures that this is for Fargate

  container_definitions = jsonencode([
    {
      name       = var.service_name
      image      = var.image_uri
      essential  = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.host_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.service_name
        }
      }
      healthCheck = {
        command     = var.health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      }
      secrets = [
        for param_path in var.ssm_parameter_paths : {
          name      = basename(param_path) # Use the base name of the SSM parameter path as the environment variable name
          valueFrom = "arn:aws:ssm:${var.region}:${var.account_id}:parameter${param_path}"
        }
      ]
    }
  ])

  tags = var.tags
  lifecycle {
    prevent_destroy = false
  }
}