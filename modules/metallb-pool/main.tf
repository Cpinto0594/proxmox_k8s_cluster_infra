# IPAddressPool + L2Advertisement for MetalLB.
#
# kubernetes_manifest talks to the API server at plan time and needs the
# MetalLB CRDs already registered, so this must be applied after the metallb
# chart (see the dependency in live/platform/metallb-config).

resource "kubernetes_manifest" "pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = var.pool_name
      namespace = var.namespace
    }
    spec = {
      addresses = var.addresses
    }
  }
}

resource "kubernetes_manifest" "l2advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = var.pool_name
      namespace = var.namespace
    }
    spec = {
      ipAddressPools = [var.pool_name]
    }
  }

  depends_on = [kubernetes_manifest.pool]
}
