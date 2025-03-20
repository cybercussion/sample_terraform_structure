include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/codestar-connection"
}

inputs = {
  connection_name = "gitlab-cybercussion"
  provider_type   = "GitLab"
}