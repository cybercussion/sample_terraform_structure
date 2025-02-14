include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/sqs"
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

inputs = {
  queue_name                 = "sqs-lambda-demo-queue"
  environment                = local.common.environment
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400  # 1 day
}