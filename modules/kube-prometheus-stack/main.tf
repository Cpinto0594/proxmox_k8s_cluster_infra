# kube-prometheus-stack: Prometheus + Alertmanager + Grafana + node-exporter +
# kube-state-metrics + the Prometheus Operator. Runs in the monitoring namespace.
# Grafana is exposed through ingress-nginx; Prometheus and Alertmanager stay
# ClusterIP (Headlamp's Prometheus plugin reaches Prometheus in-cluster).
#
# Prometheus, Alertmanager and Grafana keep their data on PVCs from
# storage_class (NFS, modules/nfs-csi), so metrics history, silences and
# dashboards made in the UI survive pod recreation.

locals {
  chart_version             = var.chart_version
  ingress_enabled           = var.ingress_enabled
  domain                    = var.domain
  homelab_subdomain         = var.homelab_subdomain
  subdomain                 = var.subdomain
  cluster_issuer            = var.cluster_issuer
  grafana_admin_password    = var.grafana_admin_password
  retention                 = var.retention
  retention_size            = var.retention_size
  loki_url                  = var.loki_url
  storage_class             = var.storage_class
  prometheus_storage_size   = var.prometheus_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size
  grafana_storage_size      = var.grafana_storage_size

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

  # Loki datasource (modules/loki), provisioned next to the default Prometheus
  # one. Empty loki_url = no Loki datasource.
  grafana_datasources = local.loki_url != "" ? [{
    name      = "Loki"
    type      = "loki"
    uid       = "loki"
    access    = "proxy"
    url       = local.loki_url
    isDefault = false
    jsonData  = { maxLines = 1000 }
  }] : []

  values = {
    # kubeadm binds these to 127.0.0.1, so their targets would always be down.
    kubeEtcd              = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeControllerManager = { enabled = false }
    kubeProxy             = { enabled = false }

    prometheus = {
      prometheusSpec = {
        retention = local.retention
        # NFS doesn't enforce the PVC size, so cap the TSDB on disk too.
        retentionSize = local.retention_size
        # Pick up ServiceMonitors/PodMonitors/rules from any namespace, not
        # only those labelled with this Helm release.
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        ruleSelectorNilUsesHelmValues           = false

        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = local.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources        = { requests = { storage = local.prometheus_storage_size } }
            }
          }
        }
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = local.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources        = { requests = { storage = local.alertmanager_storage_size } }
            }
          }
        }
      }
    }

    grafana = merge(local.grafana_password_config, {
      additionalDataSources = local.grafana_datasources

      # grafana.db (UI-made dashboards, users, settings) lives on this PVC.
      persistence = {
        enabled          = true
        type             = "pvc"
        storageClassName = local.storage_class
        accessModes      = ["ReadWriteOnce"]
        size             = local.grafana_storage_size
      }
      # Never run two Grafana pods on one SQLite file during a rollout.
      deploymentStrategy = { type = "Recreate" }

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
