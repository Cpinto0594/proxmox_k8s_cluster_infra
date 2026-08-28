include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/ingress-nginx"
}

# Ordering only. The controller Service is type LoadBalancer, so it stays
# <pending> (and `helm --wait` times out -> atomic rollback) until MetalLB
# AND an IPAddressPool exist.
dependencies {
  paths = ["../namespaces", "../metallb", "../metallb-config"]
}

inputs = {
  chart_version         = "4.11.3"
  default_ingress_class = true
}
