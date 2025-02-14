include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/codestar-connection"
}

inputs = {
  connection_name = "github-cybercussion"
}