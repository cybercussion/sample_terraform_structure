variable "allow_api_gateway" {
  description = "Whether to allow API Gateway to invoke the Lambda function."
  type        = bool
  default     = false
}

variable "lambda_function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "architecture" {
  description = "The architecture for the Lambda function. Possible values are 'x86_64' or 'arm64'."
  type        = string
  default     = "x86_64"  # Default to x86_64, but can be overridden
}

variable "memory_size" {
  description = "Memory size for the Lambda function (MB)."
  type        = number
  default     = 128  # Default
}

variable "timeout" {
  description = "Timeout for the Lambda function execution (seconds)."
  type        = number
  default     = 3  # 3 seconds, 300 5 minutes
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the Lambda function."
  type        = number
  default     = 0  # Set concurrency limit if needed
}

variable "handler" {
  description = "The function within the code file that Lambda calls to start execution."
  type        = string
}

variable "runtime" {
  description = "Runtime for the Lambda function."
  type        = string
  default     = "python3.9"
}

variable "role_arn" {
  description = "The ARN of the IAM role for the Lambda."
  type        = string
}

variable "zip_file" {
  description = "Path to the zip file containing the Lambda function code."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to assign to the Lambda function."
  type        = map(string)
  default     = {}
}

# Conditional variable for the SQS trigger
variable "has_sqs_trigger" {
  description = "Whether to add an SQS trigger to the Lambda function."
  type        = bool
  default     = false
}

variable "sqs_queue_arn" {
  description = "The ARN of the SQS queue to trigger the Lambda function."
  type        = string
  default     = ""
}