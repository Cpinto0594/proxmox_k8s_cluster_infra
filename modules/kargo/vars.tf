variable "chart_version" {
  description = "kargo chart version. null = latest; pin it (see the chart_version output) once installed."
  type        = string
  default     = null
}

variable "ingress_enabled" {
  description = "Expose the Kargo API/UI through an Ingress."
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
  description = "Subdomain label for the Kargo Ingress host."
  type        = string
  default     = "kargo"
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for the Ingress TLS cert. null = plain HTTP."
  type        = string
  default     = null
}

variable "kargo_admin_password_hash" {
  description = <<-EOT
    bcrypt hash of the Kargo admin password. Generate with:
      htpasswd -nbB admin <password> | cut -d: -f2 | sed 's/\$2y/\$2a/'
  EOT
  type        = string
  sensitive   = true
}

variable "kargo_token_signing_key" {
  description = "Key used to sign admin session tokens. Generate with: openssl rand -base64 29 | tr -d \"=+/\" | cut -c1-32"
  type        = string
  sensitive   = true
}
