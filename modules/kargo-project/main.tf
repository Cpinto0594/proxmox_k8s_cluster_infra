# One Kargo Project: its namespace, the Forgejo credential Secrets, and the
# Kargo resources (Project, ProjectConfig, Warehouse, Stages) loaded from the
# YAML files in manifests_dir. Needs the Kargo CRDs, so apply after ../kargo.
# Secrets land in tfstate (local, git-ignored), same as the other secret.hcl values.

locals {
  project_name              = var.project_name
  manifests_dir             = var.manifests_dir
  forgejo_registry_url      = var.forgejo_registry_url
  forgejo_dispatch_token    = var.forgejo_dispatch_token
  forgejo_registry_username = var.forgejo_registry_username
  forgejo_registry_password = var.forgejo_registry_password

  # Every YAML doc in the directory, keyed "<Kind>/<name>".
  docs = merge([
    for f in fileset(local.manifests_dir, "*.yaml") : {
      for d in [for raw in split("\n---\n", file("${local.manifests_dir}/${f}")) : yamldecode(raw) if trimspace(raw) != ""] :
      "${d.kind}/${d.metadata.name}" => d
    }
  ]...)

  project_docs = { for k, d in local.docs : k => d if d.kind == "Project" }
  other_docs   = { for k, d in local.docs : k => d if d.kind != "Project" }
}

# Kargo adopts an existing namespace only when it carries this label.
resource "kubernetes_namespace_v1" "project" {
  metadata {
    name   = local.project_name
    labels = { "kargo.akuity.io/project" = "true" }
  }
}

resource "kubernetes_secret_v1" "forgejo_dispatch" {
  metadata {
    name      = "forgejo-dispatch"
    namespace = kubernetes_namespace_v1.project.metadata[0].name
    labels    = { "kargo.akuity.io/cred-type" = "generic" }
  }

  data = {
    token = local.forgejo_dispatch_token
  }
}

resource "kubernetes_secret_v1" "forgejo_registry_read" {
  metadata {
    name      = "forgejo-registry-read"
    namespace = kubernetes_namespace_v1.project.metadata[0].name
    labels    = { "kargo.akuity.io/cred-type" = "image" }
  }

  data = {
    repoURL  = local.forgejo_registry_url
    username = local.forgejo_registry_username
    password = local.forgejo_registry_password
  }
}

resource "kubernetes_manifest" "project" {
  for_each = local.project_docs
  manifest = each.value

  depends_on = [kubernetes_namespace_v1.project]
}

resource "kubernetes_manifest" "resources" {
  for_each = local.other_docs
  manifest = each.value

  depends_on = [kubernetes_manifest.project, kubernetes_secret_v1.forgejo_dispatch, kubernetes_secret_v1.forgejo_registry_read]
}
