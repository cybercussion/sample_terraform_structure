terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

resource "aws_ecs_cluster" "this" {
  name = "${var.environment}-fargate-cluster"
}