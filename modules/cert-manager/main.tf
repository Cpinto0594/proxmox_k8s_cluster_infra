# cert-manager: issues and renews TLS certificates for Ingress resources.

locals {
  chart_version = var.chart_version

  release    = "cert-manager"
  namespace  = "networking"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  helm_values = {
    "crds.enabled" = "true"
  }
}

resource "helm_release" "cert_manager" {
  name             = local.release
  namespace        = local.namespace
  create_namespace = false

  repository = local.repository
  chart      = local.chart
  version    = local.chart_version

  dynamic "set" {
    for_each = local.helm_values
    content {
      name  = set.key
      value = set.value
    }
  }

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
