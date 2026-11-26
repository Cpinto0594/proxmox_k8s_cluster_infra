output "chart_version" {
  description = "Deployed alloy chart version."
  value       = helm_release.alloy.version
}

output "loki_push_url" {
  description = "Loki endpoint Alloy pushes logs to."
  value       = "${local.loki_url}/loki/api/v1/push"
}
