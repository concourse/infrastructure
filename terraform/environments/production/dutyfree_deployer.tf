resource "kubernetes_namespace" "dutyfree" {
  depends_on = [
    module.cluster
  ]

  metadata {
    name = "dutyfree"
  }
}

# This service account is to be used in CI to deploy dutyfree
resource "kubernetes_service_account" "df_deployer" {
  metadata {
    name      = "df-deployer"
    namespace = kubernetes_namespace.dutyfree.id
  }
}

resource "kubernetes_secret" "df_deployer" {
  metadata {
    name        = "df-deployer"
    namespace   = kubernetes_namespace.dutyfree.id
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.df_deployer.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

# Has access to everything within the namespace
resource "kubernetes_role" "df_deployer" {
  metadata {
    name      = "df-deployer"
    namespace = kubernetes_namespace.dutyfree.id
  }

  rule {
    api_groups     = ["*"]
    resources      = ["*"]
    verbs          = ["*"]
  }
}

resource "kubernetes_role_binding" "deployer" {
  metadata {
    name      = "df-deployer"
    namespace = kubernetes_namespace.dutyfree.id
  }
  role_ref {
    kind       = "Role"
    name       = kubernetes_role.df_deployer.metadata[0].name
    api_group  = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.df_deployer.metadata[0].name
    namespace = kubernetes_namespace.dutyfree.id
  }
}
