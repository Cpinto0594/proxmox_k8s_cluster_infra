output "chart_version" {
  description = "Deployed csi-driver-nfs chart version."
  value       = helm_release.csi_driver_nfs.version
}

output "namespace" {
  description = "Namespace the NFS CSI driver is installed in."
  value       = helm_release.csi_driver_nfs.namespace
}

output "storage_class" {
  description = "StorageClass backed by the NFS export."
  value       = local.storage_class
}
