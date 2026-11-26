variable "chart_version" {
  description = "grafana/alloy chart version."
  type        = string
  default     = "1.16.0"
}

variable "loki_url" {
  description = "Loki base URL Alloy pushes to (without /loki/api/v1/push). See the loki unit's loki_url output."
  type        = string
  default     = "http://loki.monitoring.svc:3100"
}
