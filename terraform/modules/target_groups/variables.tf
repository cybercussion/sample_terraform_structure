variable "vpc_ssm_path" {
  description = "SSM parameter path for the VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "service_name" {
  description = "Service name (e.g., my-service)"
  type        = string
}

variable "deployment_type" {
  description = "The deployment type for the ECS service: rolling, bluegreen, canary"
  type        = string
  default     = "rolling"
  validation {
    condition     = contains(["rolling", "bluegreen", "canary"], var.deployment_type)
    error_message = "Valid values for deployment_type are: rolling, bluegreen, canary."
  }
}

variable "canary_traffic_weight" {
  description = "Percentage of traffic shifted to the new (green) version in a canary deployment."
  type        = number
  default     = 20
  validation {
    condition     = var.canary_traffic_weight >= 0 && var.canary_traffic_weight <= 100
    error_message = "Canary traffic weight must be between 0 and 100."
  }
}

variable "manage_listener_rules" {
  description = "Set to true if Terraform should manage ALB listener rules (false if CodeDeploy handles them)."
  type        = bool
  default     = false  # Set to true if NOT using CodeDeploy
}

variable "base_priority" {
  type    = number
  default = 100
}

variable "enable_http" {
  description = "Enable or disable HTTP (port 80) listener"
  type        = bool
  default     = true  # Set to false to disable HTTP listener (port 80)
}

variable "container_port" {
  description = "Port for the container service"
  type        = number
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
}

variable "health_check_matcher" {
  description = "Matcher for health check responses"
  type        = string
  default     = "200" # Default to HTTP 200
}

variable "health_check_interval" {
  description = "Interval between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health check responses"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of successful checks before marking as healthy"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of failed checks before marking as unhealthy"
  type        = number
  default     = 3
}

variable "http_listener_arn" {
  description = "ARN of the HTTP listener (optional)"
  type        = string
  default     = ""
}

variable "https_listener_arn" {
  description = "ARN of the HTTPS listener (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to assign to the resources"
  type        = map(string)
  default     = {}
}