include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/kube-prometheus-stack"
}

# monitoring namespace, the ingress controller, the ClusterIssuer, and the NFS
# StorageClass must exist first.
dependencies {
  paths = ["../namespaces", "../ingress-nginx", "../cluster-issuer", "../nfs-csi"]
}

# storage_class comes from common.hcl.
inputs = {
  chart_version             = "92.22.0"
  ingress_enabled           = true
  subdomain                 = "grafana" # host is <subdomain>.<homelab_subdomain>.<domain>; both from common.hcl
  cluster_issuer            = "letsencrypt-prod"
  retention                 = "7d"
  retention_size            = "18GB"                            # below prometheus_storage_size; NFS doesn't enforce PVC size
  loki_url                  = "http://loki.monitoring.svc:3100" # = `terragrunt output loki_url` in ../loki; "" = no Loki datasource
  prometheus_storage_size   = "20Gi"
  alertmanager_storage_size = "1Gi"
  grafana_storage_size      = "5Gi"
}
