include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/namespaces"
}

inputs = {
  namespaces = {
    "monitoring" = { "managed-by" = "terragrunt" }
    "apps"       = { "managed-by" = "terragrunt" }
    "metallb-system" = {
      "managed-by" = "terragrunt"
      # MetalLB components need to run as privileged.
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}
