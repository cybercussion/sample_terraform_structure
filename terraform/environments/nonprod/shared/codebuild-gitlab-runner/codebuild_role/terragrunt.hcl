include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Load shared configuration from common.hcl
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
  #connection_arn = "arn:aws:codestar-connections:us-west-2:113510960314:connection/5202142e-ef99-4bca-a2af-b983d2bbeef8"
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/iam_role"
}

dependency "codestar_connection" {
  config_path = "../../codestar_connection_gitlab"

  mock_outputs = {
    connection_arn  = "arn:aws:codestar-connections:us-west-2:123456789012:connection/mock-connection-id"
    connection_name = "mock-connection"
  }
}

inputs = {
  role_name = "CodeBuildGitlabRunnerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policies = [] # No full AWS-managed policies for security

  inline_policies = {
    "CodeBuildGitLabRunnerPolicy" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "codebuild:StartBuild",
            "codebuild:BatchGetBuilds",
            "codebuild:ListBuilds",
            "codebuild:BatchGetProjects"
          ],
          Resource = "*"
        },
        {
          Effect = "Allow",
          Action = [
            "codestar-connections:UseConnection",
            "codestar-connections:GetConnection",
            "codestar-connections:GetConnectionToken",
            "codeconnections:GetConnection",
            "codeconnections:GetConnectionToken"
          ],
          Resource = [
            "${dependency.codestar_connection.outputs.connection_arn}",
            "arn:aws:codestar-connections:*:*:connection/",
            "arn:aws:codeconnections:*:*:connection/"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "codebuild:CreateWebhook",
            "codebuild:UpdateWebhook",
            "codebuild:DeleteWebhook"
          ],
          Resource = "arn:aws:codebuild:us-west-2:113510960314:project/*"
        },
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "arn:aws:logs:us-west-2:113510960314:log-group:/aws/codebuild/*"
        },
        {
          Effect = "Allow",
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
          ],
          Resource = "arn:aws:s3:::codepipeline-us-west-2-*"
        },
        {
          Effect = "Allow",
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
          ],
          Resource = "arn:aws:codebuild:us-west-2:113510960314:report-group/*"
        },
        {
          Effect = "Allow",
          Action = [
            "iam:PassRole"
          ],
          Resource = "arn:aws:iam::113510960314:role/CodeBuildGitLabRunnerRole",
          Condition = {
            StringEqualsIfExists = {
              "iam:PassedToService" = "codebuild.amazonaws.com"
            }
          }
        }
      ]
    })
  }
  tags = local.common.tags
}