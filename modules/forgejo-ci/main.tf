# ServiceAccount (+ long-lived token Secret) that Forgejo CI authenticates as,
# bound to the "edit" ClusterRole in each of target_namespaces so pipelines can
# deploy there. The "ci" namespace itself is created by modules/namespaces; this
# module only assumes it exists (see the dependency in live/platform/forgejo-ci).
#
# It also creates the registry pull secret in each target namespace, so deployed
# pods can pull images from the Forgejo registry (see imagePullSecrets in the
# skaffolder manifests).

locals {
  namespace            = var.namespace
  service_account_name = var.service_account_name
  target_namespaces    = var.target_namespaces
  cluster_role         = var.cluster_role

  registry_host             = var.registry_host
  registry_username         = var.forgejo_registry_username
  registry_password         = var.forgejo_registry_password
  registry_pull_secret_name = var.registry_pull_secret_name

  token_secret_name = "${local.service_account_name}-token"
}

resource "kubernetes_service_account_v1" "deployer" {
  metadata {
    name      = local.service_account_name
    namespace = local.namespace
  }
}

resource "kubernetes_secret_v1" "deployer_token" {
  metadata {
    name      = local.token_secret_name
    namespace = local.namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.deployer.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

moved {
  from = kubernetes_role_binding_v1.deployer
  to   = kubernetes_role_binding_v1.deployer["tenant-apps"]
}

resource "kubernetes_role_binding_v1" "deployer" {
  for_each = toset(local.target_namespaces)

  metadata {
    name      = local.service_account_name
    namespace = each.key
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.deployer.metadata[0].name
    namespace = local.namespace
  }

  role_ref {
    kind      = "ClusterRole"
    name      = local.cluster_role
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_secret_v1" "registry_pull" {
  for_each = toset(local.target_namespaces)

  metadata {
    name      = local.registry_pull_secret_name
    namespace = each.key
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (local.registry_host) = {
          username = local.registry_username
          password = local.registry_password
          auth     = base64encode("${local.registry_username}:${local.registry_password}")
        }
      }
    })
  }
}
