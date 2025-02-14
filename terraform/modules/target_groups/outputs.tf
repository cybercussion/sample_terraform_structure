output "blue_target_group_arn" {
  description = "The ARN of the blue target group."
  value       = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  description = "The name of the blue target group."
  value       = aws_lb_target_group.blue.name
}

# Ensure only ONE definition exists for green_target_group_name
output "green_target_group_arn" {
  description = "The ARN of the green target group."
  value       = length(aws_lb_target_group.green) > 0 ? aws_lb_target_group.green[0].arn : null
}

output "green_target_group_name" {
  description = "The name of the green target group."
  value       = length(aws_lb_target_group.green) > 0 ? aws_lb_target_group.green[0].name : null
}