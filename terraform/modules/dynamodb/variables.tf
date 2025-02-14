variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "hash_key" {
  description = "The attribute name used as the hash key (primary key)"
  type        = string
}

variable "hash_key_type" {
  description = "The type of the hash key (S for string, N for number)"
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "The attribute name used as the range key (optional)"
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "The type of the range key (S for string, N for number)"
  type        = string
  default     = "S"
}

variable "billing_mode" {
  description = "The billing mode for the DynamoDB table (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Read capacity units for PROVISIONED billing mode"
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Write capacity units for PROVISIONED billing mode"
  type        = number
  default     = null
}

variable "global_secondary_indexes" {
  description = "List of Global Secondary Index configurations"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
    read_capacity   = optional(number)
    write_capacity  = optional(number)
  }))
  default = []
}

variable "ttl_enabled" {
  description = "Enable TTL (Time to Live) on the table"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "The attribute name for TTL (required if TTL is enabled)"
  type        = string
  default     = null
}

variable "encryption_enabled" {
  description = "Enable server-side encryption for the DynamoDB table"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption. Defaults to AWS-managed key if not set."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(string)
  default     = {}
}