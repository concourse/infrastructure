data "google_secret_manager_secret_version" "wavefront_token" {
  provider = google-beta
  secret   = "wavefront_token"
}

module "wavefront" {
  source = "../../dependencies/wavefront"

  prefix = "concourse"
  # Choosing stress' address arbitrarily - the important thing is that the
  # otel_collector config sets the URL correctly, so as long as this url is
  # unique within wavefront, we should be okay
  url   = module.concourse_stress_address.dns_address
  token = data.google_secret_manager_secret_version.wavefront_token.secret_data

  depends_on = [
    module.cluster.node_pools,
  ]
}

module "cluster-metrics" {
  source           = "../../dependencies/cluster-metrics"
  url              = module.concourse_stress_address.dns_address
  metrics_endpoint = module.wavefront.metrics_endpoint

  depends_on = [
    module.cluster.node_pools,
  ]
}

resource "kubernetes_config_map" "otel_collector_stress" {
  metadata {
    name      = "otelcol-config"
    namespace = kubernetes_namespace.stress.metadata.0.name
  }

  data = {
    "otelcol.yml" = templatefile("${path.module}/otelcol.yml.tpl", {
      tracing_endpoint = module.wavefront.tracing_endpoint
      metrics_endpoint = module.wavefront.metrics_endpoint
      cluster_url      = module.concourse_stress_address.dns_address
    })
  }
}

resource "kubernetes_config_map" "otel_collector_baseline" {
  metadata {
    name      = "otelcol-config"
    namespace = kubernetes_namespace.baseline.metadata.0.name
  }

  data = {
    "otelcol.yml" = templatefile("${path.module}/otelcol.yml.tpl", {
      tracing_endpoint = module.wavefront.tracing_endpoint
      metrics_endpoint = module.wavefront.metrics_endpoint
      cluster_url      = module.concourse_baseline_address.dns_address
    })
  }
}
