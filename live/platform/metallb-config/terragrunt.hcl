include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/metallb-pool"
}

# The metallb chart (CRDs + controller) must be applied before this unit,
# because kubernetes_manifest validates against the CRDs at plan time.
dependencies {
  paths = ["../metallb"]
}

inputs = {
  namespace = "networking"
  pool_name = "lan"
  # metallb_addresses comes from common.hcl
}
