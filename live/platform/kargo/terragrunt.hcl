include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/kargo"
}

# kargo namespace, the ingress controller, cert-manager, the ClusterIssuer and Argo CD must exist first.
dependencies {
  paths = ["../namespaces", "../ingress-nginx", "../cert-manager", "../cluster-issuer", "../argocd"]
}

inputs = {
  chart_version   = null # latest; pin after first apply (see `chart_version` output)
  ingress_enabled = true
  subdomain       = "kargo" # host is <subdomain>.<homelab_subdomain>.<domain>; both from common.hcl
  cluster_issuer  = "letsencrypt-prod"
}
