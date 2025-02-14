include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/route53"
}

locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependency "s3_cloudfront" {
  config_path = "../s3_cloudfront" # Path to the s3_cloudfront terragrunt.

  # Merge mock outputs with the actual state to avoid errors during validation or planning
  mock_outputs_merge_with_state = true

  # Define mock outputs for commands that might fail without them
  mock_outputs = {
    cloudfront_endpoint = "placeholder.cloudfront.net"
  }
}

inputs = {
  ssm_domain_param      = "/network/domain"
  target_dns_name       = dependency.s3_cloudfront.outputs.cloudfront_endpoint # CloudFront distribution endpoint
  target_hosted_zone_id = "Z2FDTNDATAQYW2" # Hosted Zone ID for CloudFront
  region                = local.common.locals.aws_region
  app_name              = local.common.locals.app_name
  env                   = local.common.locals.environment
}