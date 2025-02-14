terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = var.api_description
}

# Top-level resources
resource "aws_api_gateway_resource" "resources" {
  for_each = { for k, v in var.routes : k => v if v.parent_path == null }
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.value.path_part
}

# Nested resources
resource "aws_api_gateway_resource" "nested_resources" {
  for_each = { for k, v in var.routes : k => v if v.parent_path != null }
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.resources[each.value.parent_path].id
  path_part   = each.value.path_part
}

# API Gateway methods for top-level resources
resource "aws_api_gateway_method" "top_level_methods" {
  for_each = { for k, v in var.routes : k => v if v.parent_path == null }
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resources[each.key].id
  http_method   = each.value.method
  authorization = each.value.authorization

  request_parameters = try(each.value.request_parameters, {})
  request_models     = try(each.value.request_models, {})
}

# API Gateway methods for nested resources
resource "aws_api_gateway_method" "nested_methods" {
  for_each = { for k, v in var.routes : k => v if v.parent_path != null }
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.nested_resources[each.key].id
  http_method   = each.value.method
  authorization = each.value.authorization

  request_parameters = try(each.value.request_parameters, {})
  request_models     = try(each.value.request_models, {})
}

# API Gateway integrations for top-level resources
resource "aws_api_gateway_integration" "top_level_integrations" {
  for_each = { for k, v in var.routes : k => v if v.parent_path == null }
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resources[each.key].id
  http_method             = aws_api_gateway_method.top_level_methods[each.key].http_method
  integration_http_method = try(each.value.integration_http_method, "POST")
  type                    = each.value.integration_type
  uri                     = each.value.backend_uri

  request_templates    = try(each.value.request_templates, null)
  passthrough_behavior = try(each.value.passthrough_behavior, "WHEN_NO_MATCH")
}

# API Gateway integrations for nested resources
resource "aws_api_gateway_integration" "nested_integrations" {
  for_each = { for k, v in var.routes : k => v if v.parent_path != null }
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.nested_resources[each.key].id
  http_method             = aws_api_gateway_method.nested_methods[each.key].http_method
  integration_http_method = try(each.value.integration_http_method, "POST")
  type                    = each.value.integration_type
  uri                     = each.value.backend_uri

  request_templates    = try(each.value.request_templates, null)
  passthrough_behavior = try(each.value.passthrough_behavior, "WHEN_NO_MATCH")
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.top_level_integrations, aws_api_gateway_integration.nested_integrations]
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = var.cloudwatch_log_group_arn
    format          = var.access_log_format
  }

  variables = var.stage_variables
}

resource "aws_lambda_permission" "allow_api_gateway" {
  for_each     = var.routes
  statement_id = "AllowExecutionFromApiGateway-${each.key}"
  action       = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal    = "apigateway.amazonaws.com"
  source_arn   = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
}
