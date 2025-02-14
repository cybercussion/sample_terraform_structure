output "gitlab_runner_release_name" {
  description = "The name of the Helm release for GitLab Runner"
  value       = helm_release.gitlab_runner.name
}

output "gitlab_runner_status" {
  description = "The status of the GitLab Runner Helm release"
  value       = helm_release.gitlab_runner.status
}