output "name" {
  description = "Helm release name."
  value       = helm_release.external_dns.name
}

output "namespace" {
  description = "Namespace external-dns runs in."
  value       = helm_release.external_dns.namespace
}

output "chart_version" {
  description = "Resolved chart version."
  value       = helm_release.external_dns.version
}

output "domain_filter" {
  description = "Domain suffix external-dns manages."
  value       = local.domain
}
