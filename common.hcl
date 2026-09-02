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
  domain     = "capilabs.dev"         # base domain: ingress hostnames + cert-manager DNS-01 zone
  acme_email = "cpinto0594@gmail.com" # Let's Encrypt ACME account email

  # --- MetalLB ---
  # IP ranges MetalLB hands to type=LoadBalancer Services. Must be free, outside
  # DHCP, and on an L2 segment the nodes can ARP for.
  metallb_addresses = ["192.168.30.200-192.168.30.250"]
}
