variable "service_name" {
  description = "Name of the ECS service (e.g., my-service)"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "256" # Default to 256 CPU units
}

variable "task_memory" {
  description = "Memory for the task"
  type        = string
  default     = "512" # Default to 512 MiB
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80  # Default to port 80 for NGINX, but can be overridden
}

variable "host_port" {
  description = "Port exposed to the host"
  type        = number
  default     = 80  # Default to port 80, can be changed as needed
}

variable "health_check_command" {
  description = "The command for ECS health check."
  type        = list(string)
  default     = ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]  # Default value, you can override if needed
}

variable "execution_role_arn" {
  description = "The ARN of the task execution IAM role"
  type        = string
}

variable "task_role_arn" {
  description = "The ARN of the IAM role assigned to the task"
  type        = string
}

variable "image_uri" {
  description = "Docker image URI for the container"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for the container logs"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "health_check_interval" {
  description = "Health check interval (in seconds)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout (in seconds)"
  type        = number
  default     = 5
}

variable "health_check_retries" {
  description = "Number of retries for health checks"
  type        = number
  default     = 3
}

variable "health_check_start_period" {
  description = "Start period for health checks (in seconds)"
  type        = number
  default     = 10
}

variable "ssm_parameter_paths" {
  description = "List of SSM Parameter Store paths to inject as environment variables"
  type        = list(string)
  default     = [] # Default to an empty list
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "tags" {
  description = "Tags to assign to the ECS task definition"
  type        = map(string)
  default     = {}
}