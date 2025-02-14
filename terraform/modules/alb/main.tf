terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region  # Dynamically set based on the input
}

# Fetch VPC ID from SSM
data "aws_ssm_parameter" "vpc_id" {
  name = var.vpc_ssm_path
}

# Fetch Subnets from SSM
data "aws_ssm_parameter" "subnets" {
  for_each = toset(var.subnet_ssm_paths)
  name     = each.value
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-fargate-alb"
  description = "Security group for ALB"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  # HTTP ingress (optional)
  # 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP or allow for HTTP to HTTPS redirection"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.environment}-fargate-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for ssm in data.aws_ssm_parameter.subnets : ssm.value]

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}

# Fetch Certificate ARN from SSM
data "aws_ssm_parameter" "certificate" {
  name = var.certificate_ssm_path
}

# HTTP Listener (port 80) with conditional redirection or fixed response
resource "aws_lb_listener" "http" {
  count             = var.enable_http ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No service configured yet"
      status_code  = "404"
    }
  }
}

# Redirect listener (when HTTP is disabled)
resource "aws_lb_listener" "http_redirect" {
  count             = var.enable_http ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (port 443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = data.aws_ssm_parameter.certificate.value

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No service configured yet"
      status_code  = "404"
    }
  }
}

# Test Listener (Optional)
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.this.arn
  port              = 9001
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Test listener response"
      status_code  = "200"
    }
  }
}