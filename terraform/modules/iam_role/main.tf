terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
  }

  backend "s3" {}
}

resource "aws_iam_role" "this" {
  name                  = var.role_name
  assume_role_policy    = var.assume_role_policy
  force_detach_policies = true
  # max_session_duration = 3600
  tags                  = var.tags
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