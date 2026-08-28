variable "chart_version" {
  description = "headlamp chart version."
  type        = string
  default     = "0.45.0"
}

variable "ingress_enabled" {
  description = "Expose the Headlamp UI through an Ingress."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Base domain; the Ingress host is <subdomain>.<domain>."
  type        = string
}

variable "subdomain" {
  description = "Subdomain label for the Headlamp Ingress host."
  type        = string
  default     = "headlamp"
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for the Ingress TLS cert. null = plain HTTP."
  type        = string
  default     = null
}
