output "chart_version" {
  description = "Deployed loki chart version."
  value       = helm_release.loki.version
}

output "loki_url" {
  description = "In-cluster Loki base URL: Grafana datasource URL and Alloy push target (+ /loki/api/v1/push)."
  value       = "http://${local.release}.${local.namespace}.svc:3100"
}
