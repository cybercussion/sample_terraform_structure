variable "ssm_domain_param" {
  description = "SSM Parameter name for the domain (e.g., /network/domain)."
  type        = string
}

variable "target_dns_name" {
  description = "The DNS name of the target resource (ALB or CloudFront)."
  type        = string
}

variable "evaluate_target_health" {
  description = "Whether to evaluate target health for the Route53 record"
  type        = bool
  default     = false
}

variable "target_hosted_zone_id" {
  description = "The hosted zone ID of the target resource (ALB or CloudFront)."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "env" {
  description = "The environment (e.g., dev, stage, prod)."
  type        = string
}