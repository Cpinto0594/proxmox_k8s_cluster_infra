# ingress-nginx controller, exposed on a MetalLB LoadBalancer IP.

locals {
  chart_version         = var.chart_version
  default_ingress_class = var.default_ingress_class

  release    = "ingress-nginx"
  namespace  = "networking"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  helm_values = {
    "controller.service.type"                 = "LoadBalancer"
    "controller.ingressClassResource.default" = tostring(local.default_ingress_class)
  }
}

resource "helm_release" "ingress_nginx" {
  name             = local.release
  namespace        = local.namespace
  create_namespace = false

  repository = local.repository
  chart      = local.chart
  version    = local.chart_version

  dynamic "set" {
    for_each = local.helm_values
    content {
      name  = set.key
      value = set.value
    }
  }

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
