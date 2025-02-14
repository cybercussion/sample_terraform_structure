terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  backend "s3" {}
}

# data "aws_region" "current" {}

# data "aws_caller_identity" "current" {}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy != "" ? var.assume_role_policy : jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  force_detach_policies = true 
}

resource "aws_iam_role_policy" "inline_policies" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = toset(var.managed_policies)

  role       = aws_iam_role.this.id
  policy_arn = each.value
}