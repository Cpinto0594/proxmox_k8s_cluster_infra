include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/forgejo-ci"
}

# "ci" and "apps" namespaces must exist first.
dependencies {
  paths = ["../namespaces"]
}

inputs = {
  namespace            = "ci"
  service_account_name = "forgejo-deployer"
  target_namespace     = "apps"
  cluster_role         = "edit"
}
