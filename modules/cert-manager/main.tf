# cert-manager: issues and renews TLS certificates for Ingress resources.

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version

  set {
    name  = "crds.enabled"
    value = "true"
  }

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
