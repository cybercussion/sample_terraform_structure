variable "application_name" {
  description = "CodeDeploy application name."
  type        = string
}

variable "deployment_group_name" {
  description = "Name of the CodeDeploy deployment group."
  type        = string
}

variable "service_role_arn" {
  description = "Role ARN for CodeDeploy to use."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service."
  type        = string
}

variable "blue_target_group_arn" {
  description = "ARN of the blue target group."
  type        = string
}

variable "green_target_group_arn" {
  description = "ARN of the green target group."
  type        = string
}

variable "prod_listener_arn" {
  description = "ARN of the production listener."
  type        = string
}

variable "test_listener_arn" {
  description = "ARN of the test listener."
  type        = string
}