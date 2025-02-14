output "bucket_name" {
  description = "Name of S3 bucket to hold website content"
  value       = aws_s3_bucket.spa_bucket.id
}

output "bucket_arn" {
  description = "ARN of S3 bucket to hold website content"
  value       = aws_s3_bucket.spa_bucket.arn
}

output "bucket_arn_wildcard" {
  description = "Wildcard ARN of S3 bucket to hold website content"
  value       = "${aws_s3_bucket.spa_bucket.arn}/*"
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.cf_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.cf_distribution.arn
}

output "cloudfront_endpoint" {
  description = "Endpoint for the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf_distribution.domain_name
}

output "full_domain" {
  description = "Full domain name"
  value       = nonsensitive("https://${var.app_name}-${var.env}.${data.aws_ssm_parameter.domain.value}")
}