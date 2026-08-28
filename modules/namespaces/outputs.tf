output "namespaces" {
  description = "Names of the namespaces created by this module."
  value       = sort([for ns in kubernetes_namespace.kubernetes_namespace : ns.metadata[0].name])
}
