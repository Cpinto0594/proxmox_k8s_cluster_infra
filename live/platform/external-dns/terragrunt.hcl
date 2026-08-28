include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/external-dns"
}

# namespaces: external-dns + its token Secret live in the networking namespace.
# ingress-nginx: its LoadBalancer IP is what lands in each Ingress .status and
# becomes the DNS record target.
dependencies {
  paths = ["../namespaces", "../ingress-nginx"]
}

inputs = {
  chart_version = "1.21.1"
  txt_owner_id  = "capilabs-k8s"
  policy        = "upsert-only"
}
