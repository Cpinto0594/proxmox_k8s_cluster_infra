# kube-prometheus-stack: Prometheus + Alertmanager + Grafana + node-exporter +
# kube-state-metrics + the Prometheus Operator. Runs in the monitoring namespace.
# Grafana is exposed through ingress-nginx; Prometheus and Alertmanager stay
# ClusterIP (Headlamp's Prometheus plugin reaches Prometheus in-cluster).
#
# No StorageClass exists in the cluster, so Prometheus/Grafana/Alertmanager use
# emptyDir: data is lost when a pod restarts. Add a storage provisioner and
# storageSpec/persistence before relying on history.

locals {
  chart_version          = var.chart_version
  ingress_enabled        = var.ingress_enabled
  domain                 = var.domain
  homelab_subdomain      = var.homelab_subdomain
  subdomain              = var.subdomain
  cluster_issuer         = var.cluster_issuer
  grafana_admin_password = var.grafana_admin_password
  retention              = var.retention

  release    = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  ingress_host = join(".", compact([local.subdomain, local.homelab_subdomain, local.domain]))

  tls_enabled = local.ingress_enabled && local.cluster_issuer != null

  tls_annotations = local.tls_enabled ? {
    "cert-manager.io/cluster-issuer" = local.cluster_issuer
  } : {}

  # Empty = keep the chart default admin password.
  grafana_password_config = local.grafana_admin_password != "" ? {
    adminPassword = local.grafana_admin_password
  } : {}

  values = {
    # kubeadm binds these to 127.0.0.1, so their targets would always be down.
    kubeEtcd              = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeProxy             = { enabled = false }

    prometheus = {
      prometheusSpec = {
        retention = local.retention
        # Pick up ServiceMonitors/PodMonitors/rules from any namespace, not
        # only those labelled with this Helm release.
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        ruleSelectorNilUsesHelmValues           = false
      }
    }

    grafana = merge(local.grafana_password_config, {
      ingress = {
        enabled          = local.ingress_enabled
        ingressClassName = "nginx"
        annotations      = local.tls_annotations
        hosts            = local.ingress_enabled ? [local.ingress_host] : []
        tls = local.tls_enabled ? [{
          secretName = "grafana-tls"
          hosts      = [local.ingress_host]
        }] : []
      }
    })
  }
}

# Nested values don't survive helm_release `set` blocks, so this module passes
# a values document.
resource "helm_release" "kube_prometheus_stack" {
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
