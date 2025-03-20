locals {
  aws_region = get_env("AWS_REGION", "us-west-2")  # Defaults to us-west-2 if not set
  account_id = get_aws_account_id()
  environment = "nonprod"

  # Centralized CodeBuild Configuration
  github_repo_owner = "cybercussion"
  github_repo       = "aws-codebuild-gh-runner"
  location          = "https://github.com/${local.github_repo_owner}/${local.github_repo}.git"
  # Retrieve connection details from SSM
  connection_arn    = run_cmd("aws", "ssm", "get-parameter", "--name", "/github/connection/arn", "--query", "Parameter.Value", "--output", "text")
  connection_name   = run_cmd("aws", "ssm", "get-parameter", "--name", "/github/connection/name", "--query", "Parameter.Value", "--output", "text")
  compute_type      = "BUILD_GENERAL1_SMALL"
  image             = "aws/codebuild/standard:7.0"

  tags = {
    Environment = local.environment
    Terraform   = "true"
    Team        = "platform"
    ManagedBy   = "terragrunt"
  }
}