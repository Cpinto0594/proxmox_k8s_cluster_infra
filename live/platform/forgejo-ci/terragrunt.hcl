include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/forgejo-ci"
}

# "ci" and the tenant-apps* namespaces must exist first.
dependencies {
  paths = ["../namespaces"]
}

inputs = {
  namespace            = "ci"
  service_account_name = "forgejo-deployer"
  target_namespaces    = ["tenant-apps", "tenant-apps-dev", "tenant-apps-qa", "tenant-apps-prod"]
  cluster_role         = "edit"

  registry_host             = "forgejo.homelab.capilabs.dev"
  registry_pull_secret_name = "forgejo-registry"
  # registry_username / registry_password come from secret.hcl (forgejo_registry_*)
}
