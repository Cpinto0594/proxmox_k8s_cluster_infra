# Headlamp: Kubernetes web UI. Runs in the (pre-existing) monitoring namespace
# and is exposed through the ingress-nginx controller by default.

locals {
  chart_version   = var.chart_version
  ingress_enabled = var.ingress_enabled
  domain          = var.domain
  subdomain       = var.subdomain
  cluster_issuer  = var.cluster_issuer

  release    = "headlamp"
  namespace  = "monitoring"
  repository = "https://kubernetes-sigs.github.io/headlamp/"
  chart      = "headlamp"

  ingress_host = "${local.subdomain}.${local.domain}"

  tls_enabled = local.ingress_enabled && local.cluster_issuer != null

  values = {
    ingress = {
      enabled          = local.ingress_enabled
      ingressClassName = "nginx"

      annotations = local.tls_enabled ? {
        "cert-manager.io/cluster-issuer" = local.cluster_issuer
      } : {}

      hosts = local.ingress_enabled ? [{
        host  = local.ingress_host
        paths = [{ path = "/", type = "Prefix" }]
      }] : []

      tls = local.tls_enabled ? [{
        secretName = "headlamp-tls"
        hosts      = [local.ingress_host]
      }] : []
    }
  }
}

# Nested hosts[]/paths[]/tls[] lists and the dotted annotation key don't survive
# helm_release `set` blocks cleanly, so this module passes a values document.
resource "helm_release" "headlamp" {
  name             = local.release
  namespace        = local.namespace
  create_namespace = false

  repository = local.repository
  chart      = local.chart
  version    = local.chart_version

  values = [yamlencode(local.values)]

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
