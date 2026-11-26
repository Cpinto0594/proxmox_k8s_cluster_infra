# Loki: log storage + query backend for Grafana. Runs in the monitoring
# namespace as a single binary (one StatefulSet replica, filesystem storage):
# the smallest footprint, enough for a homelab. Logs are pushed in by Alloy
# (modules/alloy) and read by Grafana's Loki datasource (kube-prometheus-stack).
#
# /var/loki (chunks, index, compactor state) is a PVC from storage_class (NFS,
# modules/nfs-csi), so logs survive pod recreation.

locals {
  chart_version    = var.chart_version
  retention_period = var.retention_period
  storage_class    = var.storage_class
  storage_size     = var.storage_size

  release    = "loki"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"

  values = {
    deploymentMode = "SingleBinary"

    loki = {
      # Single tenant: no X-Scope-OrgID needed by Alloy or Grafana.
      auth_enabled = false

      commonConfig = { replication_factor = 1 }
      storage      = { type = "filesystem" }

      schemaConfig = {
        configs = [{
          from         = "2024-04-01"
          store        = "tsdb"
          object_store = "filesystem"
          schema       = "v13"
          index        = { prefix = "loki_index_", period = "24h" }
        }]
      }

      # Merged with the chart's default limits_config.
      limits_config = { retention_period = local.retention_period }

      # The compactor enforces retention_period.
      compactor = {
        retention_enabled    = true
        delete_request_store = "filesystem"
      }
    }

    singleBinary = {
      replicas = 1
      # The chart mounts this PVC at /var/loki.
      persistence = {
        enabled      = true
        storageClass = local.storage_class
        size         = local.storage_size
        # Chart default is Delete, which would drop the PVC (and its logs) on
        # helm uninstall.
        whenDeleted = "Retain"
      }
    }

    # Zero out the simple-scalable targets (chart defaults to 3 each).
    backend = { replicas = 0 }
    read    = { replicas = 0 }
    write   = { replicas = 0 }

    # Grafana and Alloy talk to the loki Service directly.
    gateway = { enabled = false }

    # memcached caches request GBs of memory by default; not worth it here.
    chunksCache  = { enabled = false }
    resultsCache = { enabled = false }

    # helm test requires the canary; both off.
    lokiCanary = { enabled = false }
    test       = { enabled = false }
  }
}

# Nested values don't survive helm_release `set` blocks, so this module passes
# a values document.
resource "helm_release" "loki" {
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
