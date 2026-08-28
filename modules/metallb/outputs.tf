output "name" {
  description = "Helm release name."
  value       = helm_release.metallb.name
}

output "namespace" {
  description = "Namespace MetalLB is installed in."
  value       = helm_release.metallb.namespace
}

output "chart_version" {
  description = "Resolved chart version."
  value       = helm_release.metallb.version
}

output "status" {
  description = "Release status."
  value       = helm_release.metallb.status
}
