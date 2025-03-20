include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/codebuild-runner"
}

dependency "codestar_connection" {
  config_path = "../../codestar_connection_gitlab"

  mock_outputs = {
    connection_arn  = "arn:aws:codestar-connections:us-west-2:123456789012:connection/mock-connection-id"
    connection_name = "mock-connection"
  }
}

dependency "codebuild_role" {
  config_path = "../codebuild_role"

  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock-codebuild-role"
  }
}

# dependency "codestar_connection" {
#   config_path = "../../codestar-connection"

#   mock_outputs = {
#     connection_arn  = "arn:aws:codestar-connections:us-west-2:123456789012:connection/mock-connection"
#     connection_name = "gitlab-cybercussion"
#   }
# }

inputs = {
  project_name     = "gitlab-runner"
  service_role_arn = dependency.codebuild_role.outputs.role_arn
  provider_type    = "GitLab"
  repo_url         = local.common.location
  connection_arn   = dependency.codestar_connection.outputs.connection_arn
  connection_name  = dependency.codestar_connection.outputs.connection_name
  compute_type     = local.common.compute_type
  image            = local.common.image

  # Tags for resources
  tags = local.common.tags
}