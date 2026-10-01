variable "project_name" {
  description = "Kargo Project name; also the namespace. Must match metadata.name/namespace in the YAML files."
  type        = string
}

variable "manifests_dir" {
  description = "Directory with the Kargo YAML (Project, ProjectConfig, Warehouse, Stages) for this project."
  type        = string
}

variable "forgejo_registry_url" {
  description = "Image repo URL (host/owner/image) the Warehouse lists tags from. Kargo matches image credentials against the full repoURL, so a bare host does not match."
  type        = string
}

variable "forgejo_dispatch_token" {
  description = "Forgejo PAT (write:repository) the Stages use to dispatch the workflow."
  type        = string
  sensitive   = true
}

variable "forgejo_registry_username" {
  description = "Forgejo user for the registry read credential."
  type        = string
}

variable "forgejo_registry_password" {
  description = "Forgejo PAT (read:package) for the registry read credential."
  type        = string
  sensitive   = true
}
