include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/alloy"
}

# monitoring namespace must exist, and Loki should be up to receive logs.
dependencies {
  paths = ["../namespaces", "../loki"]
}

inputs = {
  chart_version = "1.16.0"
  loki_url      = "http://loki.monitoring.svc:3100" # = `terragrunt output loki_url` in ../loki
}
