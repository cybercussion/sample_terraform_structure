variable "environment" {
  description = "The environment name (e.g., dev, stage, prod). Used for naming and tagging."
  type        = string
}

variable "region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-west-2"  # You can set a default region or leave it empty to require the input
}

variable "name" {
  description = "The name of the ALB (e.g., dev-fargate-alb)."
  type        = string
}

variable "scheme" {
  description = "The scheme of the ALB (internet-facing or internal)."
  type        = string
  default     = "internet-facing"
}

variable "vpc_ssm_path" {
  description = "The SSM parameter path for the VPC ID."
  type        = string
}

variable "subnet_ssm_paths" {
  description = "List of SSM Parameter paths to retrieve public subnet IDs for the ALB."
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the ALB."
  type        = list(string)
}

variable "idle_timeout" {
  description = "The idle timeout for the ALB in seconds."
  type        = number
  default     = 60
}

variable "certificate_ssm_path" {
  description = "SSM parameter path for the HTTPS certificate ARN."
  type        = string
}

variable "enable_http" {
  description = "Flag to enable HTTP (port 80)"
  type        = bool
  default     = true  # Set to false to disable HTTP and redirect to HTTPS
}

variable "ssl_policy" {
  description = "The SSL policy for the ALB listener"
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "test_listener_port" {
  description = "Port for the test listener"
  type        = number
  default     = 9001
}

variable "tags" {
  description = "A map of tags to assign to the ALB."
  type        = map(string)
  default     = {}
}