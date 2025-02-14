include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
}

terraform {
  source = "${local.base_module_path}/ecs_cluster"
}

inputs = {
  environment = "dev"
}