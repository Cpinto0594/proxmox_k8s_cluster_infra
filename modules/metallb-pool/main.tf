# IPAddressPool + L2Advertisement for MetalLB.
#
# kubernetes_manifest talks to the API server at plan time and needs the
# MetalLB CRDs already registered, so this must be applied after the metallb
# chart (see the dependency in live/platform/metallb-config).

locals {
  namespace         = var.namespace
  pool_name         = var.pool_name
  metallb_addresses = var.metallb_addresses

  api_version = "metallb.io/v1beta1"
}

resource "kubernetes_manifest" "IPAddressPool" {
  manifest = {
    apiVersion = local.api_version
    kind       = "IPAddressPool"
    metadata = {
      name      = local.pool_name
      namespace = local.namespace
    }
    spec = {
      addresses = local.metallb_addresses
    }
  }
}

resource "kubernetes_manifest" "L2Advertisement" {
  manifest = {
    apiVersion = local.api_version
    kind       = "L2Advertisement"
    metadata = {
      name      = local.pool_name
      namespace = local.namespace
    }
    spec = {
      ipAddressPools = [local.pool_name]
    }
  }

  depends_on = [kubernetes_manifest.IPAddressPool]
}
