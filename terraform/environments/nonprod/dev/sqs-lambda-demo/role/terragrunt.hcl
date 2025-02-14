include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/iam_role"
}

dependency "sqs" {
  config_path = "../sqs"
  mock_outputs = {
    sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:mock-queue"
    sqs_queue_url = "https://sqs.us-east-1.amazonaws.com/123456789012/mock-queue"
    sqs_queue_id  = "mock-sqs-id"
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"
  mock_outputs = {
    table_name = "mock-TaskTable"
    table_arn  = "arn:aws:dynamodb:us-east-1:123456789012:table/mock-TaskTable"
  }
}

locals {
  # Load shared configuration from common.hcl
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals

  # Define Lambda function names using simplified naming
  task_lambda_name = "task-lambda-${local.common.environment}"
  task_runner_lambda_name = "task-runner-lambda-${local.common.environment}"
}

inputs = {
  # Dynamically set the role name to include the environment
  role_name = "sqs-lambda-role-${local.common.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policies = {
    # Policy for API Lambda to send messages to SQS
    "api-lambda-sqs-policy" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sqs:SendMessage",
          Effect = "Allow",
          Resource = dependency.sqs.outputs.sqs_queue_arn
        }
      ]
    })

    # Policy for Task Runner Lambda to process SQS messages
    "task-runner-sqs-policy" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
          ],
          Effect = "Allow",
          Resource = dependency.sqs.outputs.sqs_queue_arn
        }
      ]
    })

    # Policy for Lambda functions to access DynamoDB
    "lambda-dynamodb-policy" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:Query"
          ],
          Effect = "Allow",
          Resource = [
            dependency.dynamodb.outputs.table_arn,
            "${dependency.dynamodb.outputs.table_arn}/index/*"
          ]
        }
      ]
    })

    # Policy for API Gateway to invoke Lambda functions
    "api-gateway-lambda-invoke" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = "lambda:InvokeFunction",
          Effect = "Allow",
          Resource = "*"
          # Resource = [
          #   "arn:aws:lambda:${local.common.aws_region}:${local.common.account_id}:function:task-lambda-${local.common.environment}",
          #   "arn:aws:lambda:${local.common.aws_region}:${local.common.account_id}:function:task-runner-lambda-${local.common.environment}"
          # ]
        }
      ]
    })
  }

  managed_policies = [
    # Basic execution role for both Lambdas
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}