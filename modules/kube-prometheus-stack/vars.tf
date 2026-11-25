variable "chart_version" {
  description = "kube-prometheus-stack chart version."
  type        = string
  default     = "92.22.0"
}

variable "ingress_enabled" {
  description = "Expose Grafana through an Ingress."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Base domain; the Ingress host is <subdomain>[.<homelab_subdomain>].<domain>."
  type        = string
}

variable "homelab_subdomain" {
  description = "Homelab sub-zone label inserted between the app subdomain and the domain. Empty string = none."
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain label for the Grafana Ingress host."
  type        = string
  default     = "grafana"
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for the Ingress TLS cert. null = plain HTTP."
  type        = string
  default     = null
}

variable "retention" {
  description = "How long Prometheus keeps metrics (e.g. 7d). Data lives on emptyDir, so it is also lost on pod restart."
  type        = string
  default     = "7d"
}

variable "grafana_admin_password" {
  description = "Grafana admin password. Empty string keeps the chart default (prom-operator)."
  type        = string
  default     = ""
  sensitive   = true
}
