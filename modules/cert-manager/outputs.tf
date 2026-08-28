output "name" {
  description = "Helm release name."
  value       = helm_release.cert_manager.name
}

output "namespace" {
  description = "Namespace cert-manager runs in."
  value       = helm_release.cert_manager.namespace
}

output "chart_version" {
  description = "Resolved chart version."
  value       = helm_release.cert_manager.version
}
