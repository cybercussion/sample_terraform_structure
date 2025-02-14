output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.repo.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.repo.arn
}

output "placeholder_image_url" {
  description = "URL of the placeholder image, if pushed"
  value       = var.enable_placeholder_image ? "${aws_ecr_repository.repo.repository_url}:${var.placeholder_tag}" : null
}