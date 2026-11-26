variable "chart_version" {
  description = "grafana/loki chart version."
  type        = string
  default     = "7.7.0"
}

variable "retention_period" {
  description = "How long Loki keeps logs (e.g. 168h)."
  type        = string
  default     = "168h"
}

variable "storage_class" {
  description = "StorageClass for the Loki PVC at /var/loki (see modules/nfs-csi)."
  type        = string
}

variable "storage_size" {
  description = "Loki PVC size."
  type        = string
  default     = "20Gi"
}
