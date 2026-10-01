# Kargo: continuous promotion for Kubernetes (Akuity). Runs in its own `kargo`
# namespace; the API/UI is exposed through ingress-nginx with a cert-manager cert.
# Kargo's webhooks use cert-manager certs, so cert-manager must already be installed.
# Argo CD (namespace `argocd`) must be installed too: Kargo's integration is on by default.

locals {
  chart_version             = var.chart_version
  ingress_enabled           = var.ingress_enabled
  domain                    = var.domain
  homelab_subdomain         = var.homelab_subdomain
  subdomain                 = var.subdomain
  cluster_issuer            = var.cluster_issuer
  kargo_admin_password_hash = var.kargo_admin_password_hash
  kargo_token_signing_key   = var.kargo_token_signing_key

  release    = "kargo"
  namespace  = "kargo"
  repository = "oci://ghcr.io/akuity/kargo-charts"
  chart      = "kargo"

  ingress_host = join(".", compact([local.subdomain, local.homelab_subdomain, local.domain]))

  tls_enabled = local.ingress_enabled && local.cluster_issuer != null

  tls_annotations = local.tls_enabled ? {
    "cert-manager.io/cluster-issuer" = local.cluster_issuer
  } : {}

  # The Kargo API serves TLS itself (Service port 443), so nginx must talk HTTPS upstream.
  backend_annotations = {
    "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
  }

  values = {
    api = {
      host = local.ingress_host # chart reads api.host, not api.ingress.host

      adminAccount = {
        enabled         = true
        passwordHash    = local.kargo_admin_password_hash
        tokenSigningKey = local.kargo_token_signing_key
      }

      ingress = {
        enabled          = local.ingress_enabled
        ingressClassName = "nginx"
        annotations      = merge(local.tls_annotations, local.backend_annotations)

        tls = {
          enabled        = local.tls_enabled
          selfSignedCert = false # cert-manager issues the cert via the annotation above
        }
      }
    }
  }
}

# Nested values and the dotted annotation key don't survive helm_release `set`
# blocks cleanly, so this module passes a values document.
resource "helm_release" "kargo" {
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
