output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  description = "The security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = var.enable_http ? aws_lb_listener.http[0].arn : aws_lb_listener.https.arn  # Default to HTTPS listener if HTTP is disabled
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener for the ALB"
  value       = aws_lb_listener.https.arn
}

output "prod_listener_arn" {
  description = "The ARN of the production listener (HTTP or HTTPS)"
  value       = var.enable_http ? aws_lb_listener.http[0].arn : aws_lb_listener.https.arn
}

output "test_listener_arn" {
  description = "The ARN of the test listener"
  value       = aws_lb_listener.test.arn
}