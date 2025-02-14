include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/lambda"
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs = {
    sqs_queue_id  = "mock-sqs-id"
    sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
    sqs_queue_url = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
  }
}

dependency "iam_role" {
  config_path = "../role"

  mock_outputs = {
    role_arn = "arn:aws:iam::123456789012:role/mock-role"
  }
}

# Used for managing sqs taskId status (could also use S3)
dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs = {
    table_name = "mock-TaskTable"
    table_arn  = "arn:aws:dynamodb:us-east-1:123456789012:table/mock-TaskTable"
  }
}

inputs = {
  lambda_function_name   = "task-runner-lambda-${local.common.environment}"
  handler                = "lambda_task_runner.handler"
  runtime                = "python3.9"
  zip_file               = "${get_terragrunt_dir()}/../../../../artifacts/lambda_task_runner.zip"
  
  role_arn               = dependency.iam_role.outputs.role_arn
  environment_variables  = {
    environment          = local.common.environment
    SQS_QUEUE_URL        = dependency.sqs.outputs.sqs_queue_url
    DYNAMODB_TABLE_NAME  = dependency.dynamodb.outputs.table_name
  }

  tags = {
    Environment = local.common.environment
    Name        = "task-runner-lambda-${local.common.environment}"
  }

  # Enable the SQS trigger for Task Runner Lambda
  has_sqs_trigger = true
  sqs_queue_arn   = dependency.sqs.outputs.sqs_queue_arn
  
  # Lambda compute resources
  memory_size            = 128  # 1024 - 1 GB memory
  timeout                = 60   # 5 minutes
  reserved_concurrent_executions = -1

  # Enable ARM architecture
  architecture           = "x86_64"  # Change to "arm64" for ARM-based execution
}