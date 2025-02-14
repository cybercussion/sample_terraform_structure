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
  # Correctly referencing the environment from common.hcl
  role_name          = "${local.common.environment}-ecsTaskRole"
  
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
            "logs:CreateLogGroup",  # Ensure log group can be created if it doesn't exist
            "logs:CreateLogStream", # Allow creating log streams
            "logs:PutLogEvents",    # Allow putting log events into the log stream
            "logs:PutRetentionPolicy" # Optional: Allow setting retention policy for log groups
          ],
          # Correctly use local values for region and account_id
          Resource = "arn:aws:logs:${local.common.aws_region}:${local.common.account_id}:log-group:/ecs/*"
        },
        {
          Effect = "Allow",
          Action = [
            "ecs:DescribeTasks",
            "ecs:ListTasks",
            "ecs:DescribeTaskDefinition"
          ],
          Resource = [
            "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:task/${local.common.environment}-${local.common.service_name}-*",
            "arn:aws:ecs:${local.common.aws_region}:${local.common.account_id}:cluster/${local.common.environment}-cluster"
          ]
          #Resource = "*"
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
            "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/blue-tg/*",
            "arn:aws:elasticloadbalancing:${local.common.aws_region}:${local.common.account_id}:targetgroup/green-tg/*"
          ]
          #Resource = "*"
        }
      ]
    })
  }

  # Merge the tags, including the environment from common.hcl
  tags = merge(
    local.common.tags,
    {
      Name        = "${local.common.environment}-ecsTaskRole"  # Use environment here
      Application = local.common.service_name
    }
  )
}