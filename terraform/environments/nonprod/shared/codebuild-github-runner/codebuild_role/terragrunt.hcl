include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Load shared configuration from common.hcl
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
  connection_arn = "arn:aws:codestar-connections:YOUR-REGION:YOUR-ACCOUNT-ID:connection/GET IT FROM CODESTAR CONNECTION"
}

terraform {
  source = "../../../../../modules/iam_role"
}

inputs = {
  role_name = "CodeBuildGitHubRunnerRole"

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

  # TODO: Hook into default region, account local / common.hcl for targeted policies.
  inline_policies = {
    "CodeBuildGitHubRunnerPolicy" = jsonencode({
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
            "${local.connection_arn}",
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
          Resource = "arn:aws:codebuild:YOUR-REGION:YOUR-ACCOUNT:project/*"
        },
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "arn:aws:logs:YOUR REGION:YOUR ACCOUNT ID:log-group:/aws/codebuild/*"
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
          Resource = "arn:aws:codebuild:YOUR REGION:YOUR ACCOUNT ID:report-group/*"
        },
        {
          Effect = "Allow",
          Action = [
            "iam:PassRole"
          ],
          Resource = "arn:aws:iam::YOUR ACCOUNT ID:role/CodeBuildGitHubRunnerRole",
          Condition = {
            StringEqualsIfExists = {
              "iam:PassedToService" = "codebuild.amazonaws.com"
            }
          }
        }
      ]
    })
  }
}