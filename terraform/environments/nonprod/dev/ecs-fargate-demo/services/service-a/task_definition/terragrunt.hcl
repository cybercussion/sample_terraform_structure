include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/task_definition"
}

# Dependency on the execution_role module
dependency "task_execution_role" {
  config_path = "../task_execution_role"

  mock_outputs_merge_with_state = true
  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/ecsExecutionRole"
  }
}

# Dependency on the task_role module
dependency "task_role" {
  config_path = "../task_role"

  mock_outputs_merge_with_state = true
  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/ecsTaskRole"
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_merge_with_state = true
  mock_outputs = {
    repository_url = "123456789012.dkr.ecr.us-west-2.amazonaws.com/${local.common.project_name}-${local.common.service_name}-${local.common.environment}"
  }
}

inputs = {
  service_name              = local.common.service_name
  task_cpu                  = "256"
  task_memory               = "512"
  container_port            = local.common.port              # Docker Container Port (EXPOSE)
  host_port                 = local.common.port
  execution_role_arn        = dependency.task_execution_role.outputs.role_arn
  task_role_arn             = dependency.task_role.outputs.role_arn
  image_uri                 = "${dependency.ecr.outputs.repository_url}:latest"
  log_group_name            = "/ecs/${local.common.environment}-${local.common.service_name}-log-group"  # Use local.service_name
  region                    = local.common.aws_region
  account_id                = local.common.account_id
  ssm_parameter_paths       = [
    "/creds/TEST/user",
    "/creds/TEST/pwd"
  ]
  health_check_interval     = 30
  health_check_timeout      = 5
  health_check_retries      = 3
  health_check_start_period = 10
  health_check_command = ["CMD-SHELL", "curl -f http://localhost:${local.common.port}${local.common.health_check_path} || exit 1"]

  tags = merge(
    local.common.tags, 
    {
      Application = local.common.service_name
    }
  )
}