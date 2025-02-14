include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/security_group"
}

inputs = {
  name_prefix  = "dev-fargate-sg"
  description  = "Security group for ALB in dev environment"
  vpc_ssm_path = "/network/vpc"

  ingress_rules = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    },
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]

  egress_rules = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1" # All protocols
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]

  tags = {
    Environment = "dev"
    Application = "fargate"
  }
}