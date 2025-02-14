terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}


resource "aws_launch_template" "this" {
  name_prefix   = var.name_prefix
  image_id      = var.image_id
  instance_type = var.instance_type

  # Optional: add more parameters depending on your use case
  key_name = var.key_name

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}