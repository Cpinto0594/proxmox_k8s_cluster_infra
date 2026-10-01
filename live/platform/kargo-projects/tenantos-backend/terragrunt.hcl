include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/kargo-project"
}

# Kargo (and its CRDs) must be installed first.
dependencies {
  paths = ["../../kargo"]
}

inputs = {
  project_name         = "tenantos-backend"
  manifests_dir        = "${get_parent_terragrunt_dir()}/kargo-projects-configs/tenant-os"
  forgejo_registry_url = "forgejo.homelab.capilabs.dev/homelab/tenantos-backend" # must match the Warehouse repoURL
  # forgejo_dispatch_token, forgejo_registry_username and forgejo_registry_password come from secret.hcl
}
