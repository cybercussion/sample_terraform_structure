include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/s3_cloudfront"
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = {
  ssm_cert_param   = "/network/cert"
  ssm_domain_param = "/network/domain"
  region    = local.common.locals.aws_region
  app_name  = local.common.locals.app_name
  env       = local.common.locals.environment
}