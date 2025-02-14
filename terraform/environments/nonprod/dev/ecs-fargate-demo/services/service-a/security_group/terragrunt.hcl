include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/security_group"
}

dependency "alb" {
  config_path = "../../../alb"

  mock_outputs_merge_with_state = true
  mock_outputs = {
    alb_security_group_id = "sg-12345678"
  }
}

inputs = {
  vpc_ssm_path    = "/network/vpc"
  name_prefix     = "dev-${local.common.service_name}"
  description     = "Security group for ECS service"
  ingress_rules = [
    {
      from_port       = local.common.port
      to_port         = local.common.port
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = [dependency.alb.outputs.alb_security_group_id]
    }
  ]
  egress_rules = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
  tags = merge(
    local.common.tags,
    {
      Application = local.common.service_name
    }
  )
}