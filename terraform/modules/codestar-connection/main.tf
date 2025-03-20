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

resource "aws_codestarconnections_connection" "this" {
  name          = var.connection_name
  provider_type = var.provider_type  # Now dynamic

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

# Store CodeStar Connection ARN in AWS SSM Parameter Store
resource "aws_ssm_parameter" "codestar_connection_arn" {
  name  = "/${lower(var.provider_type)}/connection/arn"
  type  = "String"
  value = aws_codestarconnections_connection.this.arn
}

# Store CodeStar Connection Name in AWS SSM Parameter Store
resource "aws_ssm_parameter" "codestar_connection_name" {
  name  = "/${lower(var.provider_type)}/connection/name"
  type  = "String"
  value = aws_codestarconnections_connection.this.name
}

# Need a way to give pause while user authorizes this codestar connection with SaaS git Provider
resource "null_resource" "manual_auth_prompt" {
  depends_on = [aws_codestarconnections_connection.this]

  provisioner "local-exec" {
    command = <<EOT
      echo "Go to the AWS Console and authorize the CodeStar connection: ${aws_codestarconnections_connection.this.arn}"
      if [ -t 0 ]; then
        echo "Press Enter when done..."
        read -r
      else
        echo "Non-interactive mode detected. Skipping manual confirmation."
      fi
    EOT
    interpreter = ["bash", "-c"]
  }
}