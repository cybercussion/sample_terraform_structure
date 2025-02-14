output "autoscaling_target_arn" {
  description = "The ARN of the autoscaling target"
  value       = aws_appautoscaling_target.this.arn
}

output "scale_up_policy_arn" {
  description = "The ARN of the scale-up policy"
  value       = aws_appautoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "The ARN of the scale-down policy"
  value       = aws_appautoscaling_policy.scale_down.arn
}