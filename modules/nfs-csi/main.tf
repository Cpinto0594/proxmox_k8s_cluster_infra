# csi-driver-nfs: dynamic PersistentVolumes on an existing NFS export (the NAS).
# Each PVC gets its own sub-directory, <namespace>-<pvc name>, under nfs_share.
# The chart also creates the StorageClass, marked as the cluster default.
#
# onDelete = retain keeps a PVC's directory on the NAS when the PVC is deleted,
# and the fixed subDir name means a re-created PVC with the same name re-uses
# it, so data survives a full uninstall/reinstall. Remove stale directories on
# the NAS by hand.
#
# The node plugin mounts NFS itself (hostNetwork, privileged), so the storage
# namespace is PSA privileged and the nodes need no nfs-common package.

locals {
  chart_version     = var.chart_version
  nfs_server        = var.nfs_server
  nfs_share         = var.nfs_share
  storage_class     = var.storage_class
  default_class     = var.default_class
  nfs_mount_options = var.nfs_mount_options

  release    = "csi-driver-nfs"
  namespace  = "storage"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"

  values = {
    controller = {
      # Needs the VolumeSnapshot CRDs, which this cluster doesn't install.
      enableSnapshotter = false
    }

    storageClass = {
      create = true
      name   = local.storage_class
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = tostring(local.default_class)
      }
      parameters = {
        server   = local.nfs_server
        share    = local.nfs_share
        subDir   = "$${pvc.metadata.namespace}-$${pvc.metadata.name}"
        onDelete = "retain"
      }
      reclaimPolicy     = "Delete"
      volumeBindingMode = "Immediate"
      mountOptions      = local.nfs_mount_options
    }
  }
}

# Nested values (and the dotted annotation key) don't survive helm_release
# `set` blocks, so this module passes a values document.
resource "helm_release" "csi_driver_nfs" {
  name             = local.release
  namespace        = local.namespace
  create_namespace = false

  repository = local.repository
  chart      = local.chart
  version    = local.chart_version

  values = [yamlencode(local.values)]

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
