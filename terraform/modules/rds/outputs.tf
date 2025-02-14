output "db_cluster_id" {
  description = "The ID of the RDS cluster."
  value       = aws_rds_cluster.aurora.id
}

output "db_cluster_endpoint" {
  description = "The endpoint of the RDS cluster."
  value       = aws_rds_cluster.aurora.endpoint
}

output "db_cluster_reader_endpoint" {
  description = "The reader endpoint of the RDS cluster."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_instance_arns" {
  description = "ARNs of all RDS cluster instances (if available)"
  value       = length(aws_rds_cluster.aurora.cluster_members) > 0 ? tolist(aws_rds_cluster.aurora.cluster_members) : []
}

output "rds_password_arn" {
  description = "Secrets Manager ARN for the RDS master password"
  value       = aws_secretsmanager_secret.aurora_credentials.arn
}

output "rds_master_user" {
  description = "The master username for the RDS cluster"
  value       = var.db_master_user
}

output "rds_master_name" {
  description = "The database name for the RDS cluster"
  value       = var.db_master_name
}