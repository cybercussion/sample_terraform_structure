variable "role_name" {
  description = "The name of the IAM role."
  type        = string
}

variable "assume_role_policy" {
  description = "The IAM policy that specifies which principals can assume the role, in JSON format."
  type        = string
  # No default - must be explicitly set
  validation {
    condition     = length(var.assume_role_policy) > 0
    error_message = "Assume role policy cannot be empty."
  }
}

variable "inline_policies" {
  description = "Map of inline policy names to their JSON definitions."
  type        = map(string)
  default     = {}
}

variable "managed_policies" {
  description = "List of managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}