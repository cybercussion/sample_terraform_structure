variable "project_name" {
  description = "Name of the CodeBuild project"
  type        = string
}

variable "connection_arn" {
  description = "CodeStar Connection ARN for GitHub authentication"
  type        = string
}

variable "connection_name" {
  description = "CodeStar Connection Name"
  type        = string
}

variable "service_role_arn" {
  description = "IAM role ARN for CodeBuild"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
}

variable "compute_type" {
  description = "Compute type for CodeBuild"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "image" {
  description = "Docker image for CodeBuild"
  type        = string
  default     = "aws/codebuild/standard:6.0"
}

variable "tags" {
  description = "Tags for the CodeBuild project"
  type        = map(string)
  default     = {}
}