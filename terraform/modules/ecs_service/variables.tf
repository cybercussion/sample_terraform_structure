variable "aws_region" {
  description = "The AWS region where the resources are deployed."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID where the resources are deployed."
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service."
  type        = string
}

variable "cluster_arn" {
  description = "The ARN of the ECS cluster."
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster."
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

variable "task_definition_arn" {
  description = "The ARN of the ECS task definition."
  type        = string
}

# variable "task_role_arn" {
#   description = "The ARN of the ECS task role."
#   type        = string
# }

variable "desired_count" {
  description = "The desired number of tasks."
  type        = number
  default     = 2
}

variable "vpc_ssm_path" {
  description = "SSM parameter path for the VPC ID."
  type        = string
}

variable "subnet_ssm_paths" {
  description = "List of subnet SSM parameter paths for the ECS service."
  type        = list(string)
}

variable "security_groups" {
  description = "List of security groups for the ECS service."
  type        = list(string)
}

variable "container_port" {
  description = "The port the container exposes."
  type        = number
}

variable "blue_target_group_arn" {
  description = "The ARN of the blue target group."
  type        = string
}

variable "green_target_group_arn" {
  description = "The ARN of the green target group."
  type        = string
}

variable "blue_target_group_name" {
  description = "The name of the blue target group."
  type        = string
}

variable "green_target_group_name" {
  description = "The name of the green target group."
  type        = string
}

variable "http_listener_arn" {
  description = "The ARN of the HTTP listener."
  type        = string
}

variable "test_listener_arn" {
  description = "The ARN of the test listener."
  type        = string
}

variable "codedeploy_application_name" {
  description = "The name of the CodeDeploy application."
  type        = string
}

variable "codedeploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group."
  type        = string
}

variable "codedeploy_service_role_arn" {
  description = "The ARN of the CodeDeploy service role."
  type        = string
}

variable "tags" {
  description = "Tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "Enable or disable ECS service autoscaling."
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "The minimum capacity for the ECS service autoscaling."
  type        = number
}

variable "max_capacity" {
  description = "The maximum capacity for the ECS service autoscaling."
  type        = number
}

variable "cpu_target_value" {
  type        = number
  description = "Target CPU utilization for scaling"
  default     = 50
  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 1 and 100."
  }
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for scaling."
  type        = number
  default     = 75

  validation {
    condition     = var.memory_target_value > 0 && var.memory_target_value <= 100
    error_message = "Memory target value must be between 1 and 100."
  }
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale-in (seconds)."
  type        = number
  default     = 60
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scale-out (seconds)."
  type        = number
  default     = 60
}

variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling actions."
  type        = bool
  default     = false
}

variable "scheduled_scale_up_cron" {
  description = "CRON expression for scale-up schedule."
  type        = string
  default     = "cron(0 8 * * ? *)"
  validation {
    condition = can(regex("^cron\\(.*\\)$", var.scheduled_scale_up_cron))
    error_message = "The scale-up CRON expression must be in the correct format (e.g., 'cron(0 8 * * ? *)')."
  }
}

variable "scheduled_scale_down_cron" {
  description = "CRON expression for scale-down schedule."
  type        = string
  default     = "cron(0 20 * * ? *)"
  validation {
    condition = can(regex("^cron\\(.*\\)$", var.scheduled_scale_down_cron))
    error_message = "The scale-down CRON expression must be in the correct format (e.g., 'cron(0 20 * * ? *)')."
  }
}

variable "scheduled_scale_up_min_capacity" {
  description = "Minimum capacity during scale-up schedule."
  type        = number
  default     = 5
}

variable "scheduled_scale_up_max_capacity" {
  description = "Maximum capacity during scale-up schedule."
  type        = number
  default     = 10
}

variable "scheduled_scale_down_min_capacity" {
  description = "Minimum capacity during scale-down schedule."
  type        = number
  default     = 1
}

variable "scheduled_scale_down_max_capacity" {
  description = "Maximum capacity during scale-down schedule."
  type        = number
  default     = 5
}

variable "enable_service_discovery" {
  description = "Enable or disable service discovery for the ECS service."
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "The namespace ID for service discovery (e.g., from AWS Cloud Map)."
  type        = string
  default     = null
}

variable "dns_ttl" {
  description = "TTL for the service discovery DNS records."
  type        = number
  default     = 60
}