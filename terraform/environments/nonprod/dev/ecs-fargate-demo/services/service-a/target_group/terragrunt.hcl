include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/target_groups"
}

# Add dependency on the ALB module to reuse its outputs for routing configurations
dependency "alb" {
  config_path = "../../../alb"

  # Mock outputs for initial or partial deployment
  mock_outputs_merge_with_state = true
  mock_outputs = {
    http_listener_arn  = "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/dev-fargate-alb/abcd1234/efgh5678"
    https_listener_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/dev-fargate-alb/abcd1234/ijkl9012"
  }
}

inputs = {
  environment                      = local.common.environment
  service_name                     = local.common.service_name
  deployment_type                  = local.common.deployment_type
  canary_traffic_weight            = local.common.canary_traffic_weight
  manage_listener_rules            = local.common.manage_listener_rules
  container_port                   = local.common.port # this is coming from ALB (80/443) -> TG (80) -> ECS hostPort (dynamic), containerPort 8080, 3000 etc
  vpc_ssm_path                     = "/network/vpc" # SSM parameter path for the VPC ID
  health_check_path                = local.common.health_check_path
  health_check_matcher             = "200"
  health_check_interval            = 30
  health_check_timeout             = 5
  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 3
  tags = merge(
    local.common.tags,
    {
      Application = local.common.service_name  # From common.hcl
    }
  )

  # Dynamically set enable_http based on the existence of the HTTP listener ARN
  enable_http = length(dependency.alb.outputs.http_listener_arn) > 0 ? true : false

  # Conditionally set listener ARNs
  http_listener_arn = dependency.alb.outputs.http_listener_arn != "" ? dependency.alb.outputs.http_listener_arn : null
  https_listener_arn = dependency.alb.outputs.https_listener_arn
}