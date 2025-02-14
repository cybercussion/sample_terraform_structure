include {
  path = find_in_parent_folders("root.hcl")
}

# Warning Apple Silicon Macs, Watch your built types.
# exec /docker-entrypoint.sh: exec format 
# docker pull --platform linux/amd64 nginx
# docker build --platform linux/amd64 -t my-app .

locals {
  base_module_path = "${find_in_parent_folders("root.hcl")}/../modules"
  common = read_terragrunt_config(find_in_parent_folders("common.hcl")).locals
}

terraform {
  source = "${local.base_module_path}/ecr" # obtains base root.hcl location.
}

# Note: If you opt to use the *enable_placeholder_image* feature you'll need to have docker running.
inputs = {
  repository_name          = "${local.common.project_name}-${local.common.service_name}-${local.common.environment}"
  image_tag_mutability     = "IMMUTABLE"
  scan_on_push             = true
  region                   = local.common.aws_region
  enable_placeholder_image = true
  placeholder_image        = local.common.placeholder_image # health_check_command = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
  placeholder_tag          = local.common.placeholder_tag
  tags = merge(
    local.common.tags,
    {
      Application = local.common.service_name
    }
  )
}