# Argo CD: GitOps controller. Runs in its own `argocd` namespace (the namespace
# Kargo's Argo CD integration expects) and is exposed through ingress-nginx.
# TLS terminates at the Ingress, so argocd-server runs in insecure (plain HTTP) mode.

locals {
  chart_version                = var.chart_version
  ingress_enabled              = var.ingress_enabled
  domain                       = var.domain
  homelab_subdomain            = var.homelab_subdomain
  subdomain                    = var.subdomain
  cluster_issuer               = var.cluster_issuer
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt

  release    = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  ingress_host = join(".", compact([local.subdomain, local.homelab_subdomain, local.domain]))

  tls_enabled = local.ingress_enabled && local.cluster_issuer != null

  tls_annotations = local.tls_enabled ? {
    "cert-manager.io/cluster-issuer" = local.cluster_issuer
  } : {}

  # Empty = chart generates argocd-initial-admin-secret.
  admin_password_config = local.argocd_admin_password_bcrypt != "" ? {
    argocdServerAdminPassword = local.argocd_admin_password_bcrypt
  } : {}

  values = {
    global = {
      domain = local.ingress_host
    }

    configs = {
      params = {
        "server.insecure" = true
      }
      secret = local.admin_password_config
    }

    server = {
      ingress = {
        enabled          = local.ingress_enabled
        ingressClassName = "nginx"
        hostname         = local.ingress_host
        annotations      = local.tls_annotations
        tls              = local.tls_enabled
      }
    }
  }
}

# Nested values and dotted keys don't survive helm_release `set` blocks
# cleanly, so this module passes a values document.
resource "helm_release" "argocd" {
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
