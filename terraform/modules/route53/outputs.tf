output "dns_name" {
  description = "The created DNS name."
  value       = nonsensitive(aws_route53_record.dns_record.name)
}

output "hosted_zone_id" {
  description = "The hosted zone ID of the Route53 domain."
  value       = data.aws_route53_zone.hosted_zone.zone_id
}