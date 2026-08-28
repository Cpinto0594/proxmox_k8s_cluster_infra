variable "namespaces" {
  description = <<-EOT
    Namespaces to create, as namespace => { service => { label => value } }.
    Each service lists the labels IT needs; the module unions them onto the
    namespace (pod-security and friends are namespace-scoped in Kubernetes).
  EOT
  type        = map(map(map(string)))
}
