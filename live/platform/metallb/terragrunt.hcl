include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/metallb"
}

# The networking namespace is created by the namespaces unit.
dependencies {
  paths = ["../namespaces"]
}

inputs = {
  chart_version = "0.14.9"
}
