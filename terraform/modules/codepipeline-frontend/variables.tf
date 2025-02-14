variable "branches" {
  description = "List of branches and their configurations"
  type = list(object({
    branch_name       = string
    env               = string
    node_env          = string
    manual            = bool
  }))
  default = [
    { branch_name = "develop", env = "dev",   node_env = "dev",   manual = false },
    { branch_name = "release", env = "stage", node_env = "stage", manual = true  },
    { branch_name = "release", env = "perf",  node_env = "perf",  manual = true  }
  ]
}

variable "pipeline_name" {
  description = "The name of the CodePipeline"
  type        = string
}

variable "artifact_bucket" {
  description = "The S3 bucket to store pipeline artifacts"
  type        = string
}

variable "github_connection_arn" {
  description = "CodeStar connection ARN for GitHub/Bitbucket"
  type        = string
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
}

variable "codebuild_policies" {
  description = "IAM policy statements for CodeBuild"
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

variable "build_stages" {
  description = "Configuration for pipeline stages (Lint, Test, Build, Deploy)"
  type = map(object({
    enabled         = bool
    buildspec       = string
    compute_type    = string
    build_image     = string
    node_env        = string
    category        = string
    input_artifacts = list(string)
    output_artifacts = list(string)
    manual          = bool
  }))
  default = {
    "lint" = {
      enabled         = true
      buildspec       = "cicd/buildspecs/lint.yml"
      compute_type    = "BUILD_GENERAL1_SMALL"
      build_image     = "aws/codebuild/standard:7.0"
      node_env        = "lint"
      category        = "Test"
      input_artifacts = ["SourceOutput"]
      output_artifacts = ["LintOutput"]
      manual          = false
    },
    "test" = {
      enabled         = true
      buildspec       = "cicd/buildspecs/test.yml"
      compute_type    = "BUILD_GENERAL1_SMALL"
      build_image     = "aws/codebuild/standard:7.0"
      node_env        = "test"
      category        = "Test"
      input_artifacts = ["SourceOutput"]
      output_artifacts = ["TestOutput"]
      manual          = false
    },
    "build" = {
      enabled         = true
      buildspec       = "cicd/buildspecs/build.yml"
      compute_type    = "BUILD_GENERAL1_SMALL"
      build_image     = "aws/codebuild/standard:7.0"
      node_env        = "build"
      category        = "Build"
      input_artifacts = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      manual          = false
    },
    "deploy" = {
      enabled         = false
      buildspec       = "cicd/buildspecs/deploy.yml"
      compute_type    = "BUILD_GENERAL1_SMALL"
      build_image     = "aws/codebuild/standard:7.0"
      node_env        = "deploy"
      category        = "Deploy"
      input_artifacts = ["BuildOutput"]
      output_artifacts = []
      manual          = true
    }
  }
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "deploy_s3_bucket" {
  description = "S3 bucket for deployment artifacts"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  type        = string
}