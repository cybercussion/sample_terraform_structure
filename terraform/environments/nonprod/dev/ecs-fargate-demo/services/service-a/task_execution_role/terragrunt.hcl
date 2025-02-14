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
  role_name          = "${local.common.environment}-${local.common.service_name}-ecsExecutionRole"  # Using environment and service_name from common.hcl
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  inline_policies = {
    ECSServiceTaskPolicy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:PutRetentionPolicy"
          ],
          Resource = "arn:aws:logs:${local.common.aws_region}:${local.common.account_id}:log-group:/ecs/${local.common.environment}-${local.common.service_name}-log-group"
        },
        {
          Effect = "Allow",
          Action = [
            "ecs:DescribeTasks",
            "ecs:ListTasks",
            "ecs:DescribeTaskDefinition"
          ],
          Resource = "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:task/${local.common.environment}-${local.common.service_name}-task"
        },
        {
          Effect = "Allow",
          Action = [
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
          ],
          Resource = [
            "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/${local.common.environment}-${local.common.service_name}-blue-tg/*",
            "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/${local.common.environment}-${local.common.service_name}-green-tg/*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ecs:ExecuteCommand",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ],
          "Resource": "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:task/${local.common.environment}-${local.common.service_name}-*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "ssm:StartSession",
            "ssm:SendCommand",
            "ssm:DescribeInstanceInformation"
          ],
          "Resource": [
            "arn:aws:ssm:${local.common.aws_region}:${local.common.account_id}:document/AWS-RunShellScript",  # Specific document for shell scripts
            "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:task/${local.common.environment}-${local.common.service_name}-*"  # Specific ECS task resource ARN
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath"
          ],
          Resource = "arn:aws:ssm:${local.common.aws_region}:${local.common.account_id}:parameter/creds/*"
        }
      ]
    })
  }
  managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  tags = merge(
    local.common.tags,  # Merge tags from common.hcl
    {
      Application = local.common.service_name  # Using service_name from common.hcl
    }
  )
}