locals {
  app_name   = "sqs-lambda-demo"
  aws_region = get_env("AWS_REGION", "us-west-2")  # Defaults to us-west-2 if not set
  account_id = get_aws_account_id()
  environment = "dev"
  tags = {
    Environment = local.environment
    Terraform   = "true"
    Team        = "platform"
    ManagedBy   = "terragrunt"
  }
}