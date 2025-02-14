terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

resource "aws_codestarconnections_connection" "this" {
  name          = var.connection_name
  provider_type = "GitHub"

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}