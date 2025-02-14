# Outputs the pipeline name
output "pipeline_name" {
  description = "The name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

# Outputs the pipeline ARN
output "pipeline_arn" {
  description = "The ARN of the CodePipeline"
  value       = aws_codepipeline.pipeline.arn
}

# Outputs the artifact bucket name
output "artifact_bucket_name" {
  description = "The name of the S3 bucket used for pipeline artifacts"
  value       = aws_s3_bucket.artifact_bucket.bucket
}

# Outputs the role ARN for the CodePipeline
output "pipeline_role_arn" {
  description = "The ARN of the IAM role used by CodePipeline"
  value       = aws_iam_role.pipeline_role.arn
}

# Outputs the role ARN for CodeBuild
output "codebuild_role_arn" {
  description = "The ARN of the IAM role used by CodeBuild"
  value       = aws_iam_role.codebuild_role.arn
}

# Outputs the CodeBuild project names for all branches
output "codebuild_projects" {
  description = "A map of CodeBuild project names for all configured branches"
  value       = { for branch, project in aws_codebuild_project.build_stage : branch => project.name }
}