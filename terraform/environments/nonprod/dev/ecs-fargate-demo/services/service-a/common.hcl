locals {
  project_name          = "ecs-fargate-demo"
  service_name          = "service-a"
  port                  = "80" # Make sure this matches your target dockerfile expose.
  deployment_type       = "bluegreen" # Options: rolling, bluegreen, canary
  manage_listener_rules = true
  canary_traffic_weight = 30
  health_check_path     = "/"
  aws_region            = get_env("AWS_REGION", "us-west-2")  # Defaults to us-west-2 if not set
  account_id            = get_aws_account_id()
  environment           = "dev"
  # Map of placeholder images by port
  placeholder_tag       = "latest"
  placeholder_images = {
    "80"    = "nginx:latest"
    "3000"  = "node:20-alpine"
    "5000"  = "python:3.11-alpine"
    "8080"  = "openjdk:17-jre"
    "8501"  = "python:3.11-alpine"
    "9000"  = "php:8.2-apache"
  }
  placeholder_image = lookup(local.placeholder_images, local.port, "nginx:latest")
  tags = {
    Environment = local.environment
    Terraform   = "true"
    Team        = "platform"
    ManagedBy   = "terragrunt"
  }
}