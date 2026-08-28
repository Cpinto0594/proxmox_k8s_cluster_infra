include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/headlamp"
}

# monitoring namespace, the ingress controller, and the ClusterIssuer must exist first.
dependencies {
  paths = ["../namespaces", "../ingress-nginx", "../cluster-issuer"]
}

inputs = {
  chart_version  = "0.45.0"
  subdomain      = "headlamp" # host is <subdomain>.<domain>; domain from common.hcl
  cluster_issuer = "letsencrypt-prod"
}
