variable "connection_name" {
  description = "Name of the AWS CodeStar connection"
  type        = string
}

variable "provider_type" {
  description = "The provider type for CodeStar connection (GitHub, GitLab, Bitbucket, etc.)"
  type        = string
  validation {
    condition     = contains(["GitHub", "GitLab", "Bitbucket"], var.provider_type)
    error_message = "Valid provider types are: GitHub, GitLab, Bitbucket."
  }
}