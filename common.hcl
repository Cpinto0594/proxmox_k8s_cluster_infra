# Cluster-wide settings. Edit these to match your machine.
#
# kubeconfig_path    - override at runtime with:  export KUBECONFIG=/path/to/config
# kubeconfig_context - set to null to use whatever `kubectl config current-context` returns

locals {
  kubeconfig_path    = get_env("KUBECONFIG", "~/.kube/config")
  kubeconfig_context = "" #"kubernetes-admin@kubernetes"
}
