variable "chart_version" {
  description = "external-dns chart version."
  type        = string
  default     = "1.21.1"
}

variable "domain" {
  description = "Domain suffix external-dns manages records for (domainFilters)."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token: Zone:Read + DNS:Edit for the zone."
  type        = string
  sensitive   = true
}

variable "txt_owner_id" {
  description = "Unique owner id stamped into the TXT registry records."
  type        = string
  default     = "capilabs-k8s"
}

variable "policy" {
  description = "Record sync policy: upsert-only | sync (also deletes) | create-only."
  type        = string
  default     = "upsert-only"
}

variable "proxied" {
  description = "Create Cloudflare records proxied (orange cloud). Must be false for a private LB IP."
  type        = bool
  default     = false
}

variable "sources" {
  description = "Kubernetes resources external-dns watches."
  type        = list(string)
  default     = ["ingress"]
}
