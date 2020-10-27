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

  datadog_provider_api_key = var.datadog_api_key
  datadog_provider_app_key = var.datadog_app_key
}
