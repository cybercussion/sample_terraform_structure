include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/api_gateway"
}

locals {
  # Read configuration from common.hcl
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

dependency "lambda_task" {
  config_path = "../lambda_task"

  mock_outputs = {
    lambda_invoke_arn   = "arn:aws:lambda:${local.common.aws_region}:${local.common.account_id}:function:mock-lambda-task"
    lambda_function_name = "mock-lambda-task"
    lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:mock-task-lambda"
  }
}


inputs = {
  api_name          = "${local.common.app_name}-api"
  api_description   = "API Gateway for ${local.common.app_name}"
  stage_name        = local.common.environment
  aws_region        = local.common.aws_region
  cloudwatch_log_group_arn = "arn:aws:logs:${local.common.aws_region}:${local.common.account_id}:log-group:/aws/api-gateway/${local.common.app_name}-api"
  stage_variables   = {
    ENV = local.common.environment
  }
  tags = local.common.tags

  routes = {
    "post-task" = {
      path_part        = "task"
      parent_path      = null
      method           = "POST"
      authorization    = "NONE"
      backend_uri      = "${dependency.lambda_task.outputs.lambda_invoke_arn}"
      integration_type = "AWS_PROXY"
      lambda_function_name = dependency.lambda_task.outputs.lambda_function_name
      lambda_function_arn  = dependency.lambda_task.outputs.lambda_function_arn
    }
    "get-task-status" = {
      path_part        = "{taskId}"
      parent_path      = "post-task"
      method           = "GET"
      authorization    = "NONE"
      backend_uri      = "${dependency.lambda_task.outputs.lambda_invoke_arn}"
      integration_type = "AWS_PROXY"
      lambda_function_name = dependency.lambda_task.outputs.lambda_function_name
      lambda_function_arn  = dependency.lambda_task.outputs.lambda_function_arn
    }
  }
}