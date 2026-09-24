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

variable "headlamp_basic_auth_htpasswd" {
  description = <<-EOT
    htpasswd entry ("user:hash") for ingress-nginx basic auth on the Headlamp
    Ingress. Empty string disables basic auth. Generate with:
      htpasswd -nbBC 10 <user> <password>
  EOT
  type        = string
  default     = ""
  sensitive   = true
}
