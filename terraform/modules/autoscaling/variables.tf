variable "cluster_name" {
  description = "The ECS cluster name"
  type        = string
}

variable "service_name" {
  description = "The ECS service name"
  type        = string
}

variable "min_capacity" {
  description = "The minimum capacity for the ECS service"
  type        = number
}

variable "max_capacity" {
  description = "The maximum capacity for the ECS service"
  type        = number
}

variable "target_value" {
  description = "The target value for the scale-up policy (e.g., CPU utilization)"
  type        = number
}

variable "scale_down_target_value" {
  description = "The target value for the scale-down policy (e.g., CPU utilization)"
  type        = number
  default     = 30  # Default for scale-down
}

variable "predefined_metric" {
  description = "The predefined metric for autoscaling (e.g., ECSServiceAverageCPUUtilization)"
  type        = string
  default     = "ECSServiceAverageCPUUtilization"
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale-in (seconds)"
  type        = number
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scale-out (seconds)"
  type        = number
}

# variable "tags" {
#   description = "Tags for resources"
#   type        = map(string)
#   default     = {}
# }