output "connection_arn" {
  description = "ARN of the created CodeStar connection"
  value       = aws_codestarconnections_connection.this.arn
}

output "connection_name" {
  description = "Name of the created CodeStar connection"
  value       = aws_codestarconnections_connection.this.name
}