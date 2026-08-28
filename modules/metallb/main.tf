# MetalLB: assigns real IPs to type=LoadBalancer Services on bare metal.
# Chart only; the address pool is a separate module (metallb-pool).

resource "helm_release" "metallb" {
  name             = "metallb"
  namespace        = "metallb-system"
  create_namespace = false

  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = var.chart_version

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
