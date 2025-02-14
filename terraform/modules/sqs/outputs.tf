output "sqs_queue_id" {
  description = "The ID of the SQS queue."
  value       = aws_sqs_queue.queue.id
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue."
  value       = aws_sqs_queue.queue.arn
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue."
  value       = aws_sqs_queue.queue.url
}