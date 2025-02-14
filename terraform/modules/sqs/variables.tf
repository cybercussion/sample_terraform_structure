variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "environment" {
  description = "The environment for which the SQS queue is being created (e.g., dev, stage, prod)."
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue in seconds."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "The number of seconds to retain a message in the queue."
  type        = number
  default     = 345600  # Default to 4 days
}