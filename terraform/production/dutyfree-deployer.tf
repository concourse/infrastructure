# This service account is to be used in CI to deploy dutyfree
resource "kubernetes_namespace" "dutyfree" {
  metadata {
    name = "dutyfree"
  }
}

resource "kubernetes_service_account" "df-deployer" {
  metadata {
    name = "df-deployer"
    namespace = "dutyfree"
  }
}

resource "kubernetes_secret" "df-deployer" {
  metadata {
    name = "df-deployer"
    namespace = "dutyfree"
    annotations = {
      "kubernetes.io/service-account.name" = "df-deployer"
    }
  }

  type = "kubernetes.io/service-account-token"
}

# Has access to everything within the namespace
resource "kubernetes_role" "df-deployer" {
  metadata {
    name = "df-deployer"
    namespace = "dutyfree"
  }

  rule {
    api_groups     = ["*"]
    resources      = ["*"]
    resource_names = ["*"]
    verbs          = ["*"]
  }
}

resource "kubernetes_role_binding" "deployer" {
  metadata {
    name = "df-deployer"
  }
  role_ref {
    kind      = "Role"
    name      = "df-deployer"
    apiGroup  = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "df-deployer"
    namespace = "dutyfree"
  }
}
