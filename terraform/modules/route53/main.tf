terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0" # Or use a specific compatible version like 5.76.0
    }
  }

  backend "s3" {}
}

data "aws_ssm_parameter" "domain" {
  name = var.ssm_domain_param
}

data "aws_route53_zone" "hosted_zone" {
  name         = "${data.aws_ssm_parameter.domain.value}."
  private_zone = false
}

resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.app_name}-${var.env}.${data.aws_ssm_parameter.domain.value}"
  type    = "A"

  alias {
    name                   = var.target_dns_name
    zone_id                = var.target_hosted_zone_id
    evaluate_target_health = var.evaluate_target_health # you may not want to do this for load balancers.
  }
}