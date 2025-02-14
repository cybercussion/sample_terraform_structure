output "ecs_service_name" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "ecs_service_id" {  # Changed from ecs_service_arn to ecs_service_id
  description = "The ID of the ECS service."
  value       = aws_ecs_service.this.id  # Use id instead of arn
}

# output "codedeploy_deployment_group_arn" {
#   description = "The ARN of the CodeDeploy deployment group."
#   value       = aws_codedeploy_deployment_group.blue_green.arn
# }