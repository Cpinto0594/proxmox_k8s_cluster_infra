include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/loki"
}

# monitoring namespace and the NFS StorageClass must exist first.
dependencies {
  paths = ["../namespaces", "../nfs-csi"]
}

# storage_class comes from common.hcl.
inputs = {
  chart_version    = "7.7.0"
  retention_period = "168h" # 7d
  storage_size     = "20Gi"
}
