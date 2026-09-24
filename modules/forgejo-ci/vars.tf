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

variable "target_namespace" {
  description = "Namespace the deployer is granted access to (where the RoleBinding is created)."
  type        = string
  default     = "apps"
}

variable "cluster_role" {
  description = "ClusterRole bound to the deployer ServiceAccount, scoped to target_namespace via the RoleBinding."
  type        = string
  default     = "edit"
}
