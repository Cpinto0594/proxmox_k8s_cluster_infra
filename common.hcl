# Centralized cluster config. Non-secret values only — secrets live in secret.hcl.
# root.hcl reads this and passes every local below to every unit as an input;
# a module just declares the `variable` it consumes.

locals {
  # --- Cluster access ---
  # kubeconfig_path:    override at runtime with  export KUBECONFIG=/path/to/config
  # kubeconfig_context: "" or null = kubectl's current-context
  kubeconfig_path    = get_env("KUBECONFIG", "~/.kube/config")
  kubeconfig_context = "" # "kubernetes-admin@kubernetes"

  # --- DNS (domain managed in Cloudflare) ---
  domain            = "capilabs.dev" # base domain: ingress hostnames + cert-manager DNS-01 zone
  homelab_subdomain = "homelab"
  tenants_subdomain = "tenantos"

  acme_email = "cpinto0594@gmail.com" # Let's Encrypt ACME account email

  # --- MetalLB ---
  # IP ranges MetalLB hands to type=LoadBalancer Services. Must be free, outside
  # DHCP, and on an L2 segment the nodes can ARP for.
  metallb_addresses = ["192.168.30.210-192.168.30.250"]

  # --- Storage (NFS on the NAS, modules/nfs-csi) ---
  # The export must allow read/write from every node (192.168.30.10-13) with
  # no_root_squash. Each PVC becomes a <namespace>-<pvc> directory under nfs_share.
  nfs_server    = "192.168.20.2"  # NAS IP or hostname, e.g. "192.168.30.5"
  nfs_share     = "/volume1/k8s-prom-stack-storage" # exported path, e.g. "/volume1/k8s"
  storage_class = "nfs-csi"    # StorageClass the stateful units request
}
