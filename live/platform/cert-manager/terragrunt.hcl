include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/cert-manager"
}

# The networking namespace is created by the namespaces unit.
dependencies {
  paths = ["../namespaces"]
}

inputs = {
  chart_version = "v1.16.2"
}
