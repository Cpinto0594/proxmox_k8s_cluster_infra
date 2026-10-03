variable "namespace" {
  description = "Namespace the Forgejo deployer ServiceAccount and its token Secret live in."
  type        = string
  default     = "ci"
}

variable "service_account_name" {
  description = "Name of the ServiceAccount Forgejo CI authenticates as."
  type        = string
  default     = "forgejo-deployer"
}

variable "target_namespaces" {
  description = "Namespaces the deployer is granted access to (a RoleBinding is created in each)."
  type        = list(string)
  default     = ["tenant-apps-dev"]
}

variable "cluster_role" {
  description = "ClusterRole bound to the deployer ServiceAccount, scoped to each of target_namespaces via the RoleBinding."
  type        = string
  default     = "edit"
}

variable "registry_host" {
  description = "Forgejo registry host pods pull images from (the docker server in the pull secret)."
  type        = string
}

variable "forgejo_registry_username" {
  description = "Forgejo user for the registry pull secret."
  type        = string
}

variable "forgejo_registry_password" {
  description = "Forgejo PAT (read:package) for the registry pull secret."
  type        = string
  sensitive   = true
}

variable "registry_pull_secret_name" {
  description = "Name of the dockerconfigjson pull secret created in each target namespace."
  type        = string
  default     = "forgejo-registry"
}
