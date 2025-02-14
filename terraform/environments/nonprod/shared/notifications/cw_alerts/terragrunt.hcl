include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/notifications/cw_alerts"
}

# Mock values for the lambda ZIP
locals {
  mock_source_code_hash = "mockedhash"
  mock_filename         = "./lambda_function.zip"
}

inputs = {
  # Google Chat
  integration_url    = "https://chat.googleapis.com/v1/spaces/DOTHISLATER"
  encryption_at_rest = "No"
  region             = "us-west-2"
  
  # Use the mocked values
  source_code_hash = local.mock_source_code_hash
  filename         = local.mock_filename
}