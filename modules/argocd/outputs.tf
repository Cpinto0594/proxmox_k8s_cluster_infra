output "name" {
  description = "Helm release name."
  value       = helm_release.argocd.name
}

output "namespace" {
  description = "Namespace Argo CD runs in."
  value       = helm_release.argocd.namespace
}

output "chart_version" {
  description = "Resolved chart version."
  value       = helm_release.argocd.version
}

output "url" {
  description = "URL the UI is reachable at, when the Ingress is enabled."
  value       = local.ingress_enabled ? "${local.tls_enabled ? "https" : "http"}://${local.ingress_host}" : null
}
