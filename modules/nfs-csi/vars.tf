variable "chart_version" {
  description = "csi-driver-nfs chart version."
  type        = string
  default     = "4.13.6"
}

variable "nfs_server" {
  description = "NFS server (the NAS): IP address or hostname reachable from every node."
  type        = string
}

variable "nfs_share" {
  description = "Exported path on the NFS server; PVC directories are created under it."
  type        = string
}

variable "storage_class" {
  description = "Name of the StorageClass to create."
  type        = string
  default     = "nfs-csi"
}

variable "default_class" {
  description = "Mark the StorageClass as the cluster default (used by PVCs that name no class)."
  type        = bool
  default     = true
}

variable "nfs_mount_options" {
  description = "Mount options for every volume (e.g. [\"nfsvers=4.1\"]). Match the NFS version the NAS serves."
  type        = list(string)
  default     = ["nfsvers=4.1"]
}
