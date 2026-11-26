include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/nfs-csi"
}

# The storage namespace is created by the namespaces unit.
dependencies {
  paths = ["../namespaces"]
}

# nfs_server, nfs_share and storage_class come from common.hcl.
inputs = {
  chart_version     = "4.13.6"
  default_class     = true
  # The NAS (UGREEN DXP2800) serves NFSv3 at most. v3 locking needs rpc.statd,
  # which the CSI driver's container doesn't run ("rpc.statd is not running"),
  # so keep locks node-local with nolock. Safe here: each volume is mounted by
  # one pod at a time (RWO; Grafana uses the Recreate strategy).
  nfs_mount_options = ["nfsvers=3", "nolock"]
}
