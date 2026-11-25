include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/metrics-server"
}

# monitoring namespace must exist first.
dependencies {
  paths = ["../namespaces"]
}

inputs = {
  chart_version = "3.14.0"
}
