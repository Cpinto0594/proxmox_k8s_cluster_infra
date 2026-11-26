# Grafana Alloy: log collector (Promtail's successor). Runs as a DaemonSet in
# the monitoring namespace, tails every container log under /var/log/pods on
# its own node and pushes it to Loki (modules/loki).
#
# Labels on every stream: namespace, pod, container, node, app, job
# (= <namespace>/<container>). Query in Grafana Explore, e.g.
#   {namespace="networking", app="ingress-nginx"}

locals {
  chart_version = var.chart_version
  loki_url      = var.loki_url

  release    = "alloy"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"

  # Alloy config. The chart runs it through `tpl`, so it must not contain
  # Helm template braces. HOSTNAME is set to the node name by the chart.
  alloy_config = <<-EOT
    // Pods scheduled on this node only (each DaemonSet pod tails its own node).
    discovery.kubernetes "pods" {
      role = "pod"
      selectors {
        role  = "pod"
        field = "spec.nodeName=" + sys.env("HOSTNAME")
      }
    }

    discovery.relabel "pods" {
      targets = discovery.kubernetes.pods.targets

      rule {
        source_labels = ["__meta_kubernetes_namespace"]
        target_label  = "namespace"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_name"]
        target_label  = "pod"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_container_name"]
        target_label  = "container"
      }
      rule {
        source_labels = ["__meta_kubernetes_pod_node_name"]
        target_label  = "node"
      }
      // app = first non-empty of app.kubernetes.io/name, app, k8s-app.
      rule {
        source_labels = [
          "__meta_kubernetes_pod_label_app_kubernetes_io_name",
          "__meta_kubernetes_pod_label_app",
          "__meta_kubernetes_pod_label_k8s_app",
        ]
        separator    = ";"
        regex        = "^;*([^;]+).*$"
        replacement  = "$1"
        target_label = "app"
      }
      rule {
        source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_container_name"]
        separator     = "/"
        target_label  = "job"
      }
      // kubelet writes /var/log/pods/<ns>_<pod>_<uid>/<container>/<n>.log
      rule {
        source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
        separator     = "/"
        target_label  = "__path__"
        replacement   = "/var/log/pods/*$1/*.log"
      }
    }

    local.file_match "pods" {
      path_targets = discovery.relabel.pods.output
    }

    loki.source.file "pods" {
      targets    = local.file_match.pods.targets
      forward_to = [loki.process.pods.receiver]
    }

    // containerd writes CRI-format lines: strip the timestamp/stream prefix.
    loki.process "pods" {
      stage.cri {}
      forward_to = [loki.write.default.receiver]
    }

    loki.write "default" {
      endpoint {
        url = "${local.loki_url}/loki/api/v1/push"
      }
    }
  EOT

  values = {
    alloy = {
      configMap = { content = local.alloy_config }
      # Mount the host's /var/log (contains /var/log/pods).
      mounts = { varlog = true }
    }

    controller = {
      type = "daemonset"
      # Also collect logs from the kubeadm control-plane node.
      tolerations = [{
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
        effect   = "NoSchedule"
      }]
    }
  }
}

# Nested values (and a multi-line config string) don't survive helm_release
# `set` blocks, so this module passes a values document.
resource "helm_release" "alloy" {
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
