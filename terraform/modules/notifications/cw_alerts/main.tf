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

# KMS Key for SNS Topic
resource "aws_kms_key" "sns_topic_key" {
  description         = "CMK for SNS Topic for encryption at rest"
  enable_key_rotation = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF

  count = var.encryption_at_rest == "Yes" ? 1 : 0
}

# SNS Topic
resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "CloudwatchAlertsNotification"

  kms_master_key_id = var.encryption_at_rest == "Yes" ? aws_kms_key.sns_topic_key[0].arn : null
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alerts_lambda.arn
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Automatically zip the Lambda Python file
resource "null_resource" "zip_lambda" {
  provisioner "local-exec" {
    command = "zip -j ${path.module}/lambda_function.zip ${path.module}/lambda_function.py"
  }

  triggers = {
    python_source = filebase64sha256("${path.module}/lambda_function.py")
  }
}

# Lambda Function
resource "aws_lambda_function" "alerts_lambda" {
  depends_on = [null_resource.zip_lambda] # Ensure zip is created first

  filename         = "${path.module}/lambda_function.zip"
  function_name    = "CloudWatchAlertsFunction"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30

  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
  environment {
    variables = {
      GOOGLE_CHAT_WEBHOOK = var.integration_url
    }
  }

  # Ignore hash differences from plan to apply
  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

# SNS -> Lambda Permission
resource "aws_lambda_permission" "sns_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alerts_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_alerts.arn
}

# SSM Parameter for SNS Topic
resource "aws_ssm_parameter" "sns_topic_arn" {
  name  = "/sns/topic/cwalerts"
  type  = "String"
  value = aws_sns_topic.cloudwatch_alerts.arn
}

data "aws_caller_identity" "current" {}