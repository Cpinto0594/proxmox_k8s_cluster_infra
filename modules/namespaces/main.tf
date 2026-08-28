# Namespaces owned by the platform, created explicitly so they exist before
# the components that live in them. Helm releases targeting these namespaces
# set create_namespace = false.
#
# Input shape: namespace => { service => { label => value } }. A namespace's
# labels are the common labels plus the union of every service's label map
# (pod-security etc. are namespace-scoped, so a label one service needs is
# applied to the whole namespace).

locals {
  namespaces = var.namespaces

  common_labels = {
    "managed-by" = "terragrunt"
  }

  namespace_labels = {
    for ns, services in local.namespaces :
    ns => merge(concat([local.common_labels], values(services))...)
  }
}

resource "kubernetes_namespace" "kubernetes_namespace" {
  for_each = local.namespace_labels

  metadata {
    name   = each.key
    labels = each.value
  }
}
