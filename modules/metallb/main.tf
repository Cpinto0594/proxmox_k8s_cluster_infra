# MetalLB: assigns real IPs to type=LoadBalancer Services on bare metal.
# Chart only; the address pool is a separate module (metallb-pool).

locals {
  chart_version = var.chart_version

  release    = "metallb"
  namespace  = "networking"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
}

resource "helm_release" "metallb" {
  name             = local.release
  namespace        = local.namespace
  create_namespace = false

  repository = local.repository
  chart      = local.chart
  version    = local.chart_version

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
