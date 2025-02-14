variable "app_name" {
  description = "Please name the application. This will prefix the environment in the domain name (e.g., name-of-app-dev.domain.com)."
  type        = string
  default     = "name-of-app"
}

variable "env" {
  description = "The target environment (e.g., dev, stage, prod)."
  type        = string
  default     = "dev"
}

variable "create_dns_entry" {
  description = "Whether to add a Route53 DNS entry for the domain. Only true or false are allowed."
  type        = bool
  default     = false
}

variable "ssm_cert_param" {
  description = "SSM Parameter name for the ACM certificate ARN."
  type        = string
  default     = "/network/cert"
}

variable "ssm_domain_param" {
  description = "SSM Parameter name for the domain."
  type        = string
  default     = "/network/domain"
}