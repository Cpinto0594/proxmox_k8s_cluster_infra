include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/namespaces"
}

# namespace => { service => labels the service needs }.
# "managed-by = terragrunt" is added to every namespace by the module.
inputs = {
  namespaces = {
    "networking" = {
      "metallb"        = { "pod-security.kubernetes.io/enforce" = "privileged" }
      "ingress-nginx"  = {}
      "cert-manager"   = {}
      "cluster-issuer" = {}
      "external-dns"   = {}
    }
    "monitoring" = { "headlamp" = {} }
    "apps"       = {}
    "ci"         = {}
  }
}
