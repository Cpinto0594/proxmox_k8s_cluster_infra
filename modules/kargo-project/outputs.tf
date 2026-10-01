output "namespace" {
  description = "Namespace of the Kargo Project."
  value       = kubernetes_namespace_v1.project.metadata[0].name
}
