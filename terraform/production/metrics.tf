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

  cluster_name     = "production"
  project          = var.project
  namespace        = kubernetes_namespace.metrics.id
  subdomain        = "metrics-ci-test"
  node_pool        = "generic-1"
  cert_name        = "production-metrics"
  cert_secret_name = "production-metrics-tls"
  issuer_name      = module.cert_manager_issuer.name

  namespace_regex      = "ci|vault"
  cloudsql_instance_id = module.ci_database.instance_id
  concourse_prometheus = "http://concourse-web.${kubernetes_namespace.ci.id}.svc.cluster.local:${var.prometheus_port}"
}