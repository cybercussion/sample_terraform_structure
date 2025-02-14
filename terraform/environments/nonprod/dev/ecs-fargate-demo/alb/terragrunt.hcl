include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/alb"
}

dependency "security_group" {
  config_path = "../security_group" # Reference the security group Terragrunt config

  mock_outputs_merge_with_state = true
  mock_outputs = {
    security_group_id = "sg-1234567890abcdef"
  }
}

inputs = {
  name                = "dev-fargate-alb"
  region              = "us-west-2"  # or "us-east-1" based on your requirements
  environment         = "dev" # Added the missing 'environment' input
  scheme              = "internet-facing"
  security_group_ids  = [dependency.security_group.outputs.security_group_id]
  vpc_ssm_path        = "/network/vpc" # SSM parameter path for the VPC ID
  subnet_ssm_paths    = [
    "/network/subnet/public/1a",
    "/network/subnet/public/1b"
  ]
  certificate_ssm_path = "/network/cert/us-west-2" # SSM parameter for the certificate ARN
  ssl_policy           = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  idle_timeout         = 60
  test_listener_port   = 9001
  tags = {
    Environment = "dev"
    Application = "fargate-alb"
  }

  # New variable to enable/disable HTTP port 80
  enable_http          = false  # Set to false to disable HTTP listener (port 80)
}