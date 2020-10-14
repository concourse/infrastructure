resource "kubernetes_namespace" "metrics" {
  depends_on = [
    module.cluster
  ]

  metadata {
    name = "metrics"
  }
}

module "cert_manager_issuer" {
  source = "../cert_manager_issuer"

  cluster_name = "production"
  project      = var.project
}

module "metrics" {
  source = "../metrics"

  namespace        = kubernetes_namespace.metrics.id
  subdomain        = "metrics-ci-test"
  node_pool        = "generic-1"
  cert_name        = "production-metrics"
  cert_secret_name = "production-metrics-tls"

  namespace_regex = "ci|vault"
}