variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "The AWS region where the API Gateway is deployed"
  type        = string
}
variable "stage_name" {
  description = "The stage name for the API Gateway"
  type        = string
}

variable "routes" {
  description = "Map of routes with configuration for methods, authorization, and integrations"
  type = map(object({
    path_part             = string                   # The path for the resource (e.g., "task")
    parent_path           = optional(string, null)   # Parent path (e.g., "post-task")
    method                = string                   # HTTP method (e.g., "POST")
    authorization         = string                   # Authorization type (e.g., "NONE", "AWS_IAM")
    backend_uri           = string                   # URI for the backend integration
    integration_type      = string                   # Integration type (e.g., "AWS_PROXY", "HTTP")
    lambda_function_name  = optional(string, null)   # Lambda function name (for permissions)
    lambda_function_arn   = optional(string, null)
    request_parameters    = optional(map(bool), {})  # Optional request parameters
    request_models        = optional(map(string), {})# Optional request models
    request_templates     = optional(map(string), {})# Optional request templates
    passthrough_behavior  = optional(string, "WHEN_NO_MATCH") # Pass-through behavior
    integration_http_method = optional(string, "POST") # HTTP method for integrations
  }))
}

variable "cloudwatch_log_group_arn" {
  description = "ARN for the CloudWatch log group"
  type        = string
}

variable "access_log_format" {
  description = "Custom access log format for CloudWatch"
  type        = string
  default     = "$context.requestId $context.identity.sourceIp $context.httpMethod $context.resourcePath"
}

variable "stage_variables" {
  description = "Stage variables for the API Gateway"
  type        = map(string)
  default     = {}
}