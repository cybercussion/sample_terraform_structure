terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

data "aws_ssm_parameter" "vpc_id" {
  name = var.vpc_ssm_path
}

resource "aws_security_group" "this" {
  name_prefix = var.name_prefix
  description = var.description
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"] != null ? ingress.value["cidr_blocks"] : []
      security_groups = ingress.value["security_groups"] != null ? ingress.value["security_groups"] : []
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value["protocol"] == "-1" ? 0 : egress.value["from_port"]
      to_port     = egress.value["protocol"] == "-1" ? 0 : egress.value["to_port"]
      protocol    = egress.value["protocol"]
      cidr_blocks = egress.value["cidr_blocks"] != null ? egress.value["cidr_blocks"] : []
      security_groups = egress.value["security_groups"] != null ? egress.value["security_groups"] : []
    }
  }

  tags = var.tags
}