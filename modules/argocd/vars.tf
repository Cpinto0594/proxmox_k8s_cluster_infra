variable "chart_version" {
  description = "argo-cd chart version. null = latest; pin it (see the chart_version output) once installed."
  type        = string
  default     = null
}

variable "ingress_enabled" {
  description = "Expose the Argo CD UI/API through an Ingress."
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
  description = "Subdomain label for the Argo CD Ingress host."
  type        = string
  default     = "argocd"
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer for the Ingress TLS cert. null = plain HTTP."
  type        = string
  default     = null
}

variable "argocd_admin_password_bcrypt" {
  description = <<-EOT
    bcrypt hash of the Argo CD admin password. Empty string = let the chart
    generate one (kubectl -n argocd get secret argocd-initial-admin-secret).
    Generate with:
      htpasswd -nbBC 10 "" <password> | tr -d ':\n' | sed 's/$2y/$2a/'
  EOT
  type        = string
  default     = ""
  sensitive   = true
}
