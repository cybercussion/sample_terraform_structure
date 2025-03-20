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

data "aws_caller_identity" "current" {}

# S3 Bucket for pipeline artifacts
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = var.artifact_bucket

  lifecycle {
    prevent_destroy = false
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "artifact_bucket_versioning" {
  bucket = aws_s3_bucket.artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "artifact_bucket_lifecycle" {
  bucket = aws_s3_bucket.artifact_bucket.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "pipeline_role" {
  name = "${var.pipeline_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Policy to Pipeline Role
resource "aws_iam_role_policy" "pipeline_policy" {
  name   = "${var.pipeline_name}-pipeline-policy"
  role   = aws_iam_role.pipeline_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = "arn:aws:codestar-connections:${var.region}:${data.aws_caller_identity.current.account_id}:connection/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.artifact_bucket}",
          "arn:aws:s3:::${var.artifact_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/${var.pipeline_name}-*"
      }
    ]
  })
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.pipeline_name}-build-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach Inline Policy for CodeBuild Role
resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "${var.pipeline_name}-build-policy"
  role   = aws_iam_role.codebuild_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.pipeline_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.artifact_bucket}",
          "arn:aws:s3:::${var.artifact_bucket}/*",
          "arn:aws:s3:::${var.deploy_s3_bucket}",
          "arn:aws:s3:::${var.deploy_s3_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetProjects"
        ]
        Resource = "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
      }
    ]
  })
}

# CodeBuild Projects for pipeline stages
resource "aws_codebuild_project" "build_stage" {
  for_each = { for key, value in var.build_stages : key => value if value.enabled }

  name          = "${var.pipeline_name}-${each.key}-stage"
  description   = "CodeBuild project for the ${each.key} stage"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value.buildspec
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = each.value.compute_type
    image        = each.value.build_image
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "NODE_ENV"
      value = each.value.node_env
    }
  }
}

# Precompute the data for manual approval actions
locals {
  # Convert branches list to a map for easier access
  branches_map = {
    for branch in var.branches : branch.env => branch
  }

  # Create a map of all stages that need to be created
  all_stages = {
    for env, branch in local.branches_map : env => {
      branch_name = branch.branch_name
      node_env    = branch.node_env
      manual      = branch.manual
      category    = "Build"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput-${env}"]
    }
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.repository_name
        BranchName       = "*"
      }
    }
  }

  # Dynamic Stages
  dynamic "stage" {
    for_each = local.all_stages

    content {
      name = stage.key

      action {
        name             = stage.key
        category         = stage.value.category
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = stage.value.input_artifacts
        output_artifacts = stage.value.output_artifacts

        configuration = {
          ProjectName = aws_codebuild_project.build_stage["build"].name
        }
      }

      dynamic "action" {
        for_each = stage.value.manual ? [1] : []

        content {
          name     = "Approval-${stage.key}"
          category = "Approval"
          owner    = "AWS"
          provider = "Manual"
          version  = "1"
        }
      }
    }
  }
}