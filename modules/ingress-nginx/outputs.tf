output "name" {
  description = "Helm release name."
  value       = helm_release.ingress_nginx.name
}

output "namespace" {
  description = "Namespace the controller runs in."
  value       = helm_release.ingress_nginx.namespace
}

output "chart_version" {
  description = "Resolved chart version."
  value       = helm_release.ingress_nginx.version
}
