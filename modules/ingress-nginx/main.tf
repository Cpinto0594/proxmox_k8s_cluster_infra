# ingress-nginx controller, exposed on a MetalLB LoadBalancer IP.

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = tostring(var.default_ingress_class)
  }

  atomic      = true
  wait        = true
  timeout     = 600
  max_history = 10
}
