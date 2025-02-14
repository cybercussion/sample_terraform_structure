output "security_group_id" {
  description = "The ID of the created security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the created security group"
  value       = aws_security_group.this.arn
}