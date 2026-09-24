# Headlamp: Kubernetes web UI. Runs in the (pre-existing) monitoring namespace
# and is exposed through the ingress-nginx controller by default.

locals {
  chart_version                = var.chart_version
  ingress_enabled              = var.ingress_enabled
  domain                       = var.domain
  subdomain                    = var.subdomain
  cluster_issuer               = var.cluster_issuer
  headlamp_basic_auth_htpasswd = var.headlamp_basic_auth_htpasswd

  release    = "headlamp"
  namespace  = "monitoring"
  repository = "https://kubernetes-sigs.github.io/headlamp/"
  chart      = "headlamp"

  ingress_host = "${local.subdomain}.${local.domain}"

  tls_enabled = local.ingress_enabled && local.cluster_issuer != null

  basic_auth_enabled = local.ingress_enabled && local.headlamp_basic_auth_htpasswd != ""
  basic_auth_secret  = "${local.release}-basic-auth"

  tls_annotations = local.tls_enabled ? {
    "cert-manager.io/cluster-issuer" = local.cluster_issuer
  } : {}

  basic_auth_annotations = local.basic_auth_enabled ? {
    "nginx.ingress.kubernetes.io/auth-type"   = "basic"
    "nginx.ingress.kubernetes.io/auth-secret" = local.basic_auth_secret
    "nginx.ingress.kubernetes.io/auth-realm"  = "Headlamp"
  } : {}

  values = {
    ingress = {
      enabled          = local.ingress_enabled
      ingressClassName = "nginx"

      annotations = merge(local.tls_annotations, local.basic_auth_annotations)

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

# Basic auth on the Ingress, not the app: Headlamp itself has no
# username/password login (it authenticates via a Kubernetes token), so the
# auth boundary lives at ingress-nginx via nginx.ingress.kubernetes.io/auth-*.
resource "kubernetes_secret" "basic_auth" {
  count = local.basic_auth_enabled ? 1 : 0

  metadata {
    name      = local.basic_auth_secret
    namespace = local.namespace
  }

  data = {
    auth = local.headlamp_basic_auth_htpasswd
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

  depends_on = [kubernetes_secret.basic_auth]
}
