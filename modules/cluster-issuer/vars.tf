variable "domain" {
  description = "Base domain; the Cloudflare DNS-01 solver is scoped to this zone."
  type        = string
}

variable "acme_email" {
  description = "ACME account email registered with Let's Encrypt."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:DNS:Edit + Zone:Zone:Read for the domain."
  type        = string
  sensitive   = true
}

variable "dns_zones" {
  description = "Override for the solver's selector.dnsZones. [] = just [var.domain]."
  type        = list(string)
  default     = []
}

variable "namespace" {
  description = "Namespace the cert-manager controller runs in; where the Cloudflare API token Secret is created."
  type        = string
  default     = "networking"
}
