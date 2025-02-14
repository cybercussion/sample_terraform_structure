include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/ecs_service"
}

# Dependencies on other modules
dependency "ecs_cluster" {
  config_path = "../../../cluster"

  mock_outputs_merge_with_state = true
  mock_outputs = {
    cluster_arn  = "arn:aws:ecs:us-west-2:123456789012:cluster/mock-cluster"
    cluster_name = "mock-cluster"
  }
}

dependency "target_group" {
  config_path = "../target_group"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    blue_target_group_name  = "${local.common.environment}-blue-tg"
    green_target_group_name = "${local.common.environment}-green-tg"
    blue_target_group_arn   = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/${local.common.environment}-blue-tg/abcd1234"
    green_target_group_arn  = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/${local.common.environment}-green-tg/efgh5678"
  }
}

dependency "alb" {
  config_path = "../../../alb"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    http_listener_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/${local.common.environment}-fargate-alb/abcd1234/efgh5678"
    test_listener_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/${local.common.environment}-fargate-alb/abcd1234/test1234"
  }
}

dependency "service_security_group" {
  config_path = "../security_group"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    security_group_id = "sg-987654321"
  }
}

dependency "task_definition" {
  config_path = "../task_definition"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    task_definition_arn = "arn:aws:ecs:us-west-2:123456789012:task/${local.common.environment}-task"
  }
}

# dependency "task_role" {
#   config_path = "../task_role"
#   mock_outputs_merge_with_state = true
#   mock_outputs = {
#     role_arn = "arn:aws:iam::123456789012:role/${local.common.environment}-${local.common.service_name}-task-role"
#   }
# }

dependency "codedeploy_role" {
  config_path = "../codedeploy_role"
  mock_outputs_merge_with_state = true
  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/${local.common.environment}-${local.common.service_name}-CodeDeployRole"
  }
}

inputs = {
  # AWS Region and Account
  aws_region                       = local.common.aws_region
  account_id                       = local.common.account_id
  # ECS Service Inputs
  service_name                     = local.common.service_name
  cluster_arn                      = dependency.ecs_cluster.outputs.cluster_arn
  cluster_name                     = dependency.ecs_cluster.outputs.cluster_name
  task_definition_arn              = dependency.task_definition.outputs.task_definition_arn
  deployment_type                  = local.common.deployment_type
  canary_traffic_weight            = local.common.canary_traffic_weight
  #task_role_arn                    = dependency.task_role.outputs.task_role_arn
  desired_count                    = 1

  # SSM Parameters for VPC and Subnets
  vpc_ssm_path                     = "/network/vpc"
  subnet_ssm_paths                 = [
    "/network/subnet/public/1a",
    "/network/subnet/public/1b"
  ]

  # Networking and Load Balancer
  security_groups                  = [dependency.service_security_group.outputs.security_group_id]
  container_port                   = local.common.port
  blue_target_group_name           = dependency.target_group.outputs.blue_target_group_name
  green_target_group_name          = dependency.target_group.outputs.green_target_group_name
  blue_target_group_arn            = dependency.target_group.outputs.blue_target_group_arn
  green_target_group_arn           = dependency.target_group.outputs.green_target_group_arn
  http_listener_arn                = dependency.alb.outputs.http_listener_arn
  test_listener_arn                = dependency.alb.outputs.test_listener_arn

  # CodeDeploy Inputs
  codedeploy_application_name      = "${local.common.environment}-${local.common.service_name}-app"
  codedeploy_deployment_group_name = "${local.common.environment}-${local.common.service_name}-deployment"
  codedeploy_service_role_arn      = dependency.codedeploy_role.outputs.role_arn

  # Autoscaling Inputs
  enable_autoscaling               = true
  min_capacity                     = 1
  max_capacity                     = 5
  cpu_target_value                 = 50
  memory_target_value              = 75
  scale_in_cooldown                = 60
  scale_out_cooldown               = 60

  # Scheduled Scaling Inputs
  enable_scheduled_scaling          = true
  scheduled_scale_up_cron           = "cron(0 8 * * ? *)"  # Scale up at 8:00 AM UTC
  scheduled_scale_down_cron         = "cron(0 20 * * ? *)" # Scale down at 8:00 PM UTC
  scheduled_scale_up_min_capacity   = 3
  scheduled_scale_up_max_capacity   = 5
  scheduled_scale_down_min_capacity = 1
  scheduled_scale_down_max_capacity = 2

  # Service Discovery Inputs
  enable_service_discovery          = false
  service_discovery_namespace_id    = "ecs-sd-${local.common.environment}"  # Replace with the actual namespace ID
  dns_ttl                           = 60

  # Tags
  tags = local.common.tags
}