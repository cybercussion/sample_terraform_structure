output "api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}"
  description = "The base URL for the API Gateway, including the stage name"
}
output "api_endpoint_arn" {
  value = aws_api_gateway_rest_api.api.execution_arn
}

output "deployment_id" {
  value = aws_api_gateway_deployment.deployment.id
}

output "stage_name" {
  value = aws_api_gateway_stage.stage.stage_name
}