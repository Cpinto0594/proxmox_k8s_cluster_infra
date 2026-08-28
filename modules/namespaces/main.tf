# Namespaces owned by the platform, created explicitly so they exist before
# the components that live in them. Helm releases targeting these namespaces
# set create_namespace = false.

resource "kubernetes_namespace" "this" {
  for_each = var.namespaces

  metadata {
    name   = each.key
    labels = each.value
  }
}
