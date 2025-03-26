# Include the root configuration for backend and provider setup
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
  role_name = "${local.common.environment}-eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          AWS = [
            for user in local.common.admin_users : "arn:aws:iam::${local.common.account_id}:user/${user}"
          ]
        }
      }
    ]
  })

  inline_policies = {
    "EKSAdminPolicy" = jsonencode({
      Version = "2012-10-17",
      Statement = [
        # EKS Cluster Management
        {
          Effect = "Allow",
          Action = [
            "eks:AccessKubernetesApi",
            "eks:AssociateEncryptionConfig",
            "eks:AssociateIdentityProviderConfig",
            "eks:CreateAddon",
            "eks:CreateCluster",
            "eks:CreateFargateProfile",
            "eks:CreateNodegroup",
            "eks:DeleteAddon",
            "eks:DeleteCluster",
            "eks:DeleteFargateProfile",
            "eks:DeleteNodegroup",
            "eks:DeregisterCluster",
            "eks:DescribeAddon",
            "eks:DescribeAddonVersions",
            "eks:DescribeCluster",
            "eks:DescribeFargateProfile",
            "eks:DescribeIdentityProviderConfig",
            "eks:DescribeNodegroup",
            "eks:DescribeUpdate",
            "eks:DisassociateIdentityProviderConfig",
            "eks:ListAddons",
            "eks:ListClusters",
            "eks:ListFargateProfiles",
            "eks:ListIdentityProviderConfigs",
            "eks:ListNodegroups",
            "eks:ListTagsForResource",
            "eks:ListUpdates",
            "eks:RegisterCluster",
            "eks:TagResource",
            "eks:UntagResource",
            "eks:UpdateAddon",
            "eks:UpdateClusterConfig",
            "eks:UpdateClusterVersion",
            "eks:UpdateNodegroupConfig",
            "eks:UpdateNodegroupVersion"
          ],
          Resource = "*"
        },
        # Networking (EC2)
        {
          Effect = "Allow",
          Action = [
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcs",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeRouteTables",
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:ModifyNetworkInterfaceAttribute",
            "ec2:CreateSecurityGroup",
            "ec2:DeleteSecurityGroup",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:RevokeSecurityGroupEgress"
          ],
          Resource = "*"
        },
        # Elastic Load Balancing
        {
          Effect = "Allow",
          Action = [
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
          ],
          Resource = "*"
        },
        # CloudWatch Logs
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DeleteLogGroup",
            "logs:DeleteLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy",
            "logs:DeleteRetentionPolicy"
          ],
          Resource = "*"
        },
        # Amazon ECR
        {
          Effect = "Allow",
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchDeleteImage",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:CreateRepository",
            "ecr:DeleteRepository",
            "ecr:DescribeImages",
            "ecr:DescribeRepositories",
            "ecr:GetAuthorizationToken",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:InitiateLayerUpload",
            "ecr:ListImages",
            "ecr:PutImage",
            "ecr:SetRepositoryPolicy",
            "ecr:UploadLayerPart"
          ],
          Resource = "*"
        },
        # IAM for Fargate execution roles
        {
          Effect = "Allow",
          Action = [
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:GetRole",
            "iam:PutRolePolicy",
            "iam:DeleteRolePolicy",
            "iam:AttachRolePolicy",
            "iam:DetachRolePolicy",
            "iam:CreateServiceLinkedRole",
            "iam:ListAttachedRolePolicies",
            "iam:ListRolePolicies",
            "iam:ListInstanceProfilesForRole",
            "iam:GetRolePolicy",
            "iam:PassRole"
          ],
          Resource = [
            "arn:aws:iam::${local.common.account_id}:role/*"
          ]
        },
        # KMS permissions for encryption
        {
          Effect = "Allow",
          Action = [
            "kms:CreateGrant",
            "kms:DescribeKey",
            "kms:GetKeyPolicy",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          Resource = "*"
        }
      ]
    })
  }

  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  ]

  tags = local.common.tags
}