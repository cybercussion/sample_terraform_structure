# Include the root terragrunt configuration
include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/codedeploy"
}

# Dependencies on other modules
dependency "ecs_cluster" {
  config_path = "../../../cluster"  # Ensure this path points to the correct ECS Cluster module
  mock_outputs_merge_with_state = true
  mock_outputs = {
    cluster_arn  = "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:cluster/mock-cluster"
    cluster_name = "mock-cluster"
  }
}

dependency "ecs_service" {
  config_path = "../ecs_service"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    cluster_name    = "${local.common.environment}-cluster"
    ecs_service_name = local.common.service_name
  }
}

dependency "target_group" {
  config_path = "../target_group"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    blue_target_group_arn  = "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/${local.common.environment}-${local.common.service_name}-blue-tg/abcd1234"
    green_target_group_arn = "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/${local.common.environment}-${local.common.service_name}-green-tg/efgh5678"
  }
}

dependency "alb" {
  config_path = "../../../alb"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    test_listener_arn = "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:listener/app/${local.common.environment}-fargate-alb/abcd1234/test5678"
    prod_listener_arn = "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:listener/app/${local.common.environment}-fargate-alb/abcd1234/efgh5678"
  }
}

# Dependency for the IAM role to ensure it is created before the deployment group
dependency "codedeploy_role" {
  config_path = "../codedeploy_role"  # Make sure this points to the correct path for your IAM role
  mock_outputs_merge_with_state = true
  mock_outputs = {
    role_arn = "arn:aws:iam::${local.common.account_id}:role/${local.common.environment}-CodeDeployRole"
  }
}

inputs = {
  application_name       = "${local.common.environment}-${local.common.service_name}-cd-application"
  deployment_group_name  = "${local.common.environment}-${local.common.service_name}-cd-deployment-group"
  service_role_arn       = dependency.codedeploy_role.outputs.role_arn  # Use the IAM role ARN from the IAM role module

  cluster_name           = dependency.ecs_cluster.outputs.cluster_name
  service_name           = dependency.ecs_service.outputs.ecs_service_name

  blue_target_group_arn  = dependency.target_group.outputs.blue_target_group_arn
  green_target_group_arn = dependency.target_group.outputs.green_target_group_arn
  prod_listener_arn      = dependency.alb.outputs.prod_listener_arn
  test_listener_arn      = dependency.alb.outputs.test_listener_arn
}