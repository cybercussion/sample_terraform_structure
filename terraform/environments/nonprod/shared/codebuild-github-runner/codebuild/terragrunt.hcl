include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "../../../../../modules/codebuild-gh-runner"
}

dependency "codebuild_role" {
  config_path = "../codebuild_role"

  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock-codebuild-role"
  }
}

# TODO: hook this in later so its adopted
# dependency "codestar_connection" {
#   config_path = "../../codestar-connection"

#   mock_outputs = {
#     connection_arn  = "arn:aws:codestar-connections:us-west-2:123456789012:connection/mock-connection"
#     connection_name = "github-cybercussion"
#   }
# }

inputs = {
  project_name     = "github-runner"
  service_role_arn = dependency.codebuild_role.outputs.role_arn
  github_repo      = "https://github.com/cybercussion/aws-codebuild-gh-runner.git"
  connection_arn   = "arn:aws:codestar-connections:REGION:ACCOUNT:connection/GET-FROM-CODESTAR" # dependency.codestar_connection.outputs.connection_arn
  connection_name  = "github-cybercussion" # dependency.codestar_connection.outputs.connection_name
  compute_type     = "BUILD_GENERAL1_SMALL"
  image            = "aws/codebuild/standard:6.0"

  # Tags for resources
  tags = local.common.tags
}