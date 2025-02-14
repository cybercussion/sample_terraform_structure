include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/dynamodb"
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

inputs = {
  table_name      = "TaskTable-${local.common.environment}"
  hash_key        = "taskId"
  hash_key_type   = "S"
  billing_mode    = "PAY_PER_REQUEST"
  
  # Optionally enable TTL for automatic expiration
  ttl_enabled     = true
  ttl_attribute_name = "expiration_time"

  # Tags for the DynamoDB table
  tags = {
    Environment = local.common.environment
    Name        = "TaskTable-${local.common.environment}"
    Team        = "lambda-tasks"
  }
}