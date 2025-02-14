terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

resource "aws_sqs_queue" "queue" {
  name                        = "${var.queue_name}-${var.environment}"
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  tags = {
    Environment = var.environment
    Name        = "${var.queue_name}-${var.environment}"
  }
}