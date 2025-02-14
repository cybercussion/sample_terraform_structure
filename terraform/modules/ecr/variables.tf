variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable or disable image scan on push"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region where the ECR repository is created"
  type        = string
}

variable "tags" {
  description = "Tags to assign to the ECR repository"
  type        = map(string)
  default     = {}
}

variable "enable_placeholder_image" {
  description = "Whether to push a placeholder image to ECR"
  type        = bool
  default     = false
}

variable "placeholder_image" {
  description = "Docker image to use as the placeholder"
  type        = string
  default     = "nginx:latest"
}

variable "placeholder_tag" {
  description = "Tag for the placeholder image"
  type        = string
  default     = "latest"
}

variable "untagged_expiry_days" { default = 7 }
variable "max_tagged_images" { default = 5 }