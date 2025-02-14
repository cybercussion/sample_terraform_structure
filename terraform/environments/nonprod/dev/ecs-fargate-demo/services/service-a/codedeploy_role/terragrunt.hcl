include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/iam_role"
}

inputs = {
  role_name = "${local.common.environment}-${local.common.service_name}-ecsCodeDeployRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  inline_policies = {
    ECSCodeDeployPolicy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ecs:UpdateService",
            "ecs:DescribeServices",
            "ecs:DescribeTaskSets",
            "ecs:CreateTaskSet",
            "ecs:DeleteTaskSet"
          ],
          Resource = [
            "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:service/${local.common.environment}-fargate-cluster/${local.common.service_name}"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "ecs:DescribeServices",
            "ecs:DescribeClusters"
          ],
          Resource = [
            "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:cluster/${local.common.environment}-fargate-cluster",
            "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:service/${local.common.environment}-fargate-cluster/*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:DescribeLoadBalancers"
          ],
          Resource = [
            "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/${local.common.environment}-${local.common.service_name}-*",
            "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:loadbalancer/*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "codedeploy:CreateDeployment",
            "codedeploy:GetDeployment",
            "codedeploy:UpdateDeploymentGroup",
            "codedeploy:GetDeploymentGroup",
            "codedeploy:RegisterApplicationRevision"
          ],
          Resource = [
            "arn:aws:codedeploy:${local.common.aws_region}:${local.common.account_id}:deploymentgroup:${local.common.environment}-${local.common.service_name}-application/*",
            "arn:aws:codedeploy:${local.common.aws_region}:${local.common.account_id}:application:${local.common.environment}-${local.common.service_name}-application"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "iam:PassRole"
          ],
          Resource = [
            "arn:aws:iam::${local.common.account_id}:role/${local.common.environment}-*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "events:PutRule",
            "events:DeleteRule",
            "events:DescribeRule",
            "events:PutTargets",
            "events:RemoveTargets",
            "events:ListTargetsByRule"
          ],
          Resource = [
            "arn:aws:events:${local.common.aws_region}:${local.common.account_id}:rule/${local.common.environment}-${local.common.service_name}-*"
          ]
        }
      ]
    })
  }

  managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  tags = merge(
    local.common.tags,
    {
      Application = local.common.service_name
    }
  )
}