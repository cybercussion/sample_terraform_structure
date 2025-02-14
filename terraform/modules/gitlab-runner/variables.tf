variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The API server endpoint of the EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "The Base64 encoded certificate authority for the EKS cluster"
  type        = string
}

variable "cluster_token" {
  description = "The authentication token for the EKS cluster"
  type        = string
  sensitive   = true
}

variable "runner_release_name" {
  description = "The Helm release name for the GitLab Runner"
  type        = string
  default     = "gitlab-runner"
}

variable "namespace" {
  description = "The Kubernetes namespace for deploying GitLab Runner"
  type        = string
  default     = "default"
}

variable "chart_version" {
  description = "The GitLab Runner Helm chart version to deploy"
  type        = string
  default     = "0.42.0"
}

variable "gitlab_url" {
  description = "The URL of the GitLab instance"
  type        = string
}

variable "registration_token" {
  description = "The registration token for the GitLab Runner"
  type        = string
  sensitive   = true
}

variable "runner_token" {
  description = "The registration token for the GitLab Runner"
  type        = string
  sensitive   = true
}

variable "runners_name" {
  description = "The name of the GitLab Runner"
  type        = string
}

variable "runner_tag_list" {
  description = "A list of tags to assign to the runner"
  type        = list(string)
  default     = []
}

variable "service_account_name" {
  description = "The Kubernetes service account for the runner pods"
  type        = string
  default     = "gitlab-runner"
}

variable "pod_annotations" {
  description = "Annotations to apply to GitLab Runner pods"
  type        = map(string)
  default     = {}
}

variable "concurrent" {
  description = "Maximum number of jobs to run concurrently"
  type        = number
  default     = 10
}

variable "check_interval" {
  description = "Interval in seconds between checking for new jobs"
  type        = number
  default     = 30
}

variable "additional_helm_values" {
  description = "Additional Helm values to customize the deployment"
  type        = map(string)
  default     = {}
}