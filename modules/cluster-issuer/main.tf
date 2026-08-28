# Let's Encrypt ClusterIssuers (staging + prod) that solve ACME DNS-01
# challenges through the Cloudflare API. DNS-01 works for private/LAN hostnames
# since it never needs an inbound HTTP request.
#
# kubernetes_manifest validates against the cert-manager CRDs at plan time, so
# this is applied after the cert-manager chart (see the dependency in
# live/platform/cluster-issuer).

locals {
  domain               = var.domain
  acme_email           = var.acme_email
  cloudflare_api_token = var.cloudflare_api_token
  dns_zones            = length(var.dns_zones) > 0 ? var.dns_zones : [var.domain]
  namespace            = var.namespace

  api_version       = "cert-manager.io/v1"
  token_secret_name = "cloudflare-api-token"
  token_secret_key  = "api-token"

  issuers = {
    "letsencrypt-staging" = "https://acme-staging-v02.api.letsencrypt.org/directory"
    "letsencrypt-prod"    = "https://acme-v02.api.letsencrypt.org/directory"
  }

  dns01_solver = {
    dns01 = {
      cloudflare = {
        apiTokenSecretRef = {
          name = local.token_secret_name
          key  = local.token_secret_key
        }
      }
    }
    selector = {
      dnsZones = local.dns_zones
    }
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

resource "kubernetes_manifest" "cluster_issuer" {
  for_each = local.issuers

  manifest = {
    apiVersion = local.api_version
    kind       = "ClusterIssuer"
    metadata = {
      name = each.key
    }
    spec = {
      acme = {
        server = each.value
        email  = local.acme_email
        privateKeySecretRef = {
          name = "${each.key}-account-key"
        }
        solvers = [local.dns01_solver]
      }
    }
  }

  depends_on = [kubernetes_secret_v1.cloudflare_api_token]
}
