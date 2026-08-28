variable "chart_version" {
  description = "ingress-nginx chart version."
  type        = string
  default     = "4.11.3"
}

variable "default_ingress_class" {
  description = "Make this controller the cluster's default IngressClass."
  type        = bool
  default     = true
}
