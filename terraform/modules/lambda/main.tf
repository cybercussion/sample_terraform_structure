terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
  }
  backend "s3" {}
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  runtime       = var.runtime
  role          = var.role_arn
  handler       = var.handler
  filename      = var.zip_file

  architectures = [var.architecture]

  memory_size   = var.memory_size
  timeout       = var.timeout

  environment {
    variables = var.environment_variables
  }

  tags = var.tags

  # Use source_code_hash to detect changes in the zip file
  source_code_hash = filebase64sha256(var.zip_file)

  # Optionally set concurrency limit
  reserved_concurrent_executions = var.reserved_concurrent_executions
}

resource "aws_lambda_permission" "allow_api_gateway" {
  count = var.allow_api_gateway ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
}

# Conditionally add the SQS trigger
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  count = var.has_sqs_trigger ? 1 : 0  # Only create the event source if has_sqs_trigger is true

  event_source_arn = var.sqs_queue_arn  # The correct ARN of the SQS queue
  function_name    = aws_lambda_function.this.arn  # The Lambda function ARN
  batch_size       = 10  # Number of messages to send to Lambda
  enabled          = true  # Ensure it's enabled
}