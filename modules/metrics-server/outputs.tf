output "chart_version" {
  description = "Deployed metrics-server chart version."
  value       = helm_release.metrics_server.version
}
