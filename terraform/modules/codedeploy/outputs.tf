output "deployment_group_name" {
  value       = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
  description = "The name of the deployment group."
}

output "deployment_group_arn" {
  value       = aws_codedeploy_deployment_group.deployment_group.arn
  description = "The ARN of the deployment group."
}

output "application_name" {
  value       = aws_codedeploy_app.this.name
  description = "The name of the CodeDeploy application."
}