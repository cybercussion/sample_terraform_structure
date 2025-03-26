# Include the root terragrunt configuration for remote state
include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/iam_role"
}

inputs = {
  role_name = "nonprod-eks-cluster-fargate-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  inline_policies = {
    "FargatePodExecutionPolicy" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        # Permissions for ECR
        {
          Effect = "Allow",
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
          ],
          Resource = "*"
        },
        # Permissions for CloudWatch Logs
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "*"
        },
        # Permissions for S3 (optional, if pipelines need artifact storage)
        {
          Effect = "Allow",
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ],
          Resource = "arn:aws:s3:::your-bucket-name/*"
        },
        # Permissions for CloudFormation (if deploying infrastructure via CI/CD)
        {
          Effect = "Allow",
          Action = [
            "cloudformation:CreateStack",
            "cloudformation:UpdateStack",
            "cloudformation:DeleteStack",
            "cloudformation:DescribeStacks"
          ],
          Resource = "arn:aws:cloudformation:*:*:stack/*"
        },
        # Describe permissions for EC2, VPC, and EKS
        {
          Effect = "Allow",
          Action = [
            "ec2:Describe*",
            "eks:DescribeCluster"
          ],
          Resource = "*"
        }
      ]
    })
  }

  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  ]
  tags = local.common.tags
}