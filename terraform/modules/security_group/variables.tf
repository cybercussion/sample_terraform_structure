variable "ingress_rules" {
  description = "List of ingress rules for the security group."
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules for the security group."
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = []
}

variable "vpc_ssm_path" {
  description = "SSM parameter path for the VPC ID."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the security group name."
  type        = string
}

variable "description" {
  description = "Description of the security group."
  type        = string
}

variable "tags" {
  description = "Tags to assign to the security group."
  type        = map(string)
  default     = {}
}