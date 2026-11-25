output "chart_version" {
  description = "Deployed kube-prometheus-stack chart version."
  value       = helm_release.kube_prometheus_stack.version
}

output "grafana_url" {
  description = "Grafana URL (when the Ingress is enabled)."
  value       = local.ingress_enabled ? "${local.tls_enabled ? "https" : "http"}://${local.ingress_host}" : null
}

output "prometheus_service" {
  description = "In-cluster Prometheus address, for Headlamp's Prometheus plugin."
  value       = "${local.release}-prometheus.${local.namespace}:9090"
}
