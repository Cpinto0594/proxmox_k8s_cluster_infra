# metrics-server: serves the metrics.k8s.io API (CPU/memory per node and pod).
# Headlamp and `kubectl top` read from it. Runs in the monitoring namespace.
# kubeadm kubelets use self-signed serving certs, hence --kubelet-insecure-tls.

locals {
  chart_version = var.chart_version

  release    = "metrics-server"
  namespace  = "monitoring"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"

  values = {
    "args[0]" = "--kubelet-insecure-tls"
  }
}

resource "helm_release" "metrics_server" {
  name             = local.release
  namespace        = local.namespace
  create_namespace = false

  repository = local.repository
  chart      = local.chart
  version    = local.chart_version

  dynamic "set" {
    for_each = local.values
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
