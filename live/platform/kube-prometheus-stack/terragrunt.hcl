include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/kube-prometheus-stack"
}

# monitoring namespace, the ingress controller, and the ClusterIssuer must exist first.
dependencies {
  paths = ["../namespaces", "../ingress-nginx", "../cluster-issuer"]
}

inputs = {
  chart_version   = "92.22.0"
  ingress_enabled = true
  subdomain       = "grafana" # host is <subdomain>.<homelab_subdomain>.<domain>; both from common.hcl
  cluster_issuer  = "letsencrypt-prod"
  retention       = "7d"
}
