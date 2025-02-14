output "sns_topic_arn" {
  description = "ARN of the SNS Topic"
  value       = aws_sns_topic.cloudwatch_alerts.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda Function"
  value       = aws_lambda_function.alerts_lambda.arn
}