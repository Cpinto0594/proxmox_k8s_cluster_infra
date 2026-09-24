# ServiceAccount (+ long-lived token Secret) that Forgejo CI authenticates as,
# bound to the "edit" ClusterRole in target_namespace so pipelines can deploy
# there. The "ci" namespace itself is created by modules/namespaces; this
# module only assumes it exists (see the dependency in live/platform/forgejo-ci).

locals {
  namespace            = var.namespace
  service_account_name = var.service_account_name
  target_namespace     = var.target_namespace
  cluster_role         = var.cluster_role

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

resource "kubernetes_role_binding_v1" "deployer" {
  metadata {
    name      = local.service_account_name
    namespace = local.target_namespace
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
