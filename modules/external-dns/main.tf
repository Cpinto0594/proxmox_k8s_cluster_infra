# ExternalDNS: watches Ingress objects and writes the matching Cloudflare DNS
# records, pointing them at the ingress-nginx LoadBalancer IP taken from each
# Ingress .status. The LB IP is private, so records are created DNS-only
# (proxied = false) and only resolve usefully on the LAN.

locals {
  chart_version        = var.chart_version
  domain               = var.domain
  cloudflare_api_token = var.cloudflare_api_token
  txt_owner_id         = var.txt_owner_id
  policy               = var.policy
  proxied              = var.proxied
  sources              = var.sources

  release    = "external-dns"
  namespace  = "networking"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"

  # distinct from the cluster-issuer secret of the same purpose (same namespace)
  token_secret_name = "external-dns-cloudflare-api-token"
  token_secret_key  = "api-token"

  values = {
    provider = {
      name = "cloudflare"
    }

    sources       = local.sources
    policy        = local.policy
    registry      = "txt"
    txtOwnerId    = local.txt_owner_id
    domainFilters = [local.domain]

    env = [{
      name = "CF_API_TOKEN"
      valueFrom = {
        secretKeyRef = {
          name = local.token_secret_name
          key  = local.token_secret_key
        }
      }
    }]

    # --cloudflare-proxied is a presence-only flag; omit it for the default (disabled)
    extraArgs = local.proxied ? ["--cloudflare-proxied"] : []
  }
}

resource "kubernetes_secret_v1" "cloudflare_api_token" {
  metadata {
    name      = local.token_secret_name
    namespace = local.namespace
  }

  data = {
    (local.token_secret_key) = local.cloudflare_api_token
  }

  type = "Opaque"
}

# Nested provider/env/valueFrom maps don't survive helm_release `set` blocks, so
# this module passes a values document (same approach as modules/headlamp).
resource "helm_release" "external_dns" {
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

  depends_on = [kubernetes_secret_v1.cloudflare_api_token]
}
