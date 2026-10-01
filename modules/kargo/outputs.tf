output "name" {
  description = "Helm release name."
  value       = helm_release.kargo.name
}

output "namespace" {
  description = "Namespace Kargo runs in."
  value       = helm_release.kargo.namespace
}

output "chart_version" {
  description = "Resolved chart version."
  value       = helm_release.kargo.version
}

output "url" {
  description = "URL the UI is reachable at, when the Ingress is enabled."
  value       = local.ingress_enabled ? "${local.tls_enabled ? "https" : "http"}://${local.ingress_host}" : null
}
