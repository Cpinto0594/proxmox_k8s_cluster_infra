include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/cluster-issuer"
}

# namespaces: the token Secret lives in the networking namespace.
# cert-manager: CRDs must be registered before kubernetes_manifest can validate.
dependencies {
  paths = ["../namespaces", "../cert-manager"]
}

# domain + acme_email come from common.hcl; cloudflare_api_token from secret.hcl.
