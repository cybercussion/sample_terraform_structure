variable "integration_url" {
  description = "Google Chat webhook integration URL"
  type        = string
  sensitive   = true
}

variable "encryption_at_rest" {
  description = "Enable encryption at rest for SNS topic"
  type        = string
  default     = "Yes"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}