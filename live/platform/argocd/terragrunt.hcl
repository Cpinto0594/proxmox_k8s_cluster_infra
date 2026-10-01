include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/argocd"
}

# argocd namespace, the ingress controller, and the ClusterIssuer must exist first.
dependencies {
  paths = ["../namespaces", "../ingress-nginx", "../cluster-issuer"]
}

inputs = {
  chart_version   = null # latest; pin after first apply (see `chart_version` output)
  ingress_enabled = true
  subdomain       = "argocd" # host is <subdomain>.<homelab_subdomain>.<domain>; both from common.hcl
  cluster_issuer  = "letsencrypt-prod"
}
