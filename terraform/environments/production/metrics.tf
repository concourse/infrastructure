data "google_secret_manager_secret_version" "wavefront_token" {
  provider = google-beta
  secret   = "wavefront_token"
}

module "wavefront" {
  source = "../../dependencies/wavefront"

  prefix = "concourse"
  url    = module.concourse_ci_address.dns_address
  token  = data.google_secret_manager_secret_version.wavefront_token.secret_data

  depends_on = [
    module.cluster.node_pools,
  ]
}

module "cluster-metrics" {
  source           = "../../dependencies/cluster-metrics"
  url              = module.concourse_ci_address.dns_address
  metrics_endpoint = module.wavefront.metrics_endpoint

  depends_on = [
    module.cluster.node_pools,
  ]
}

resource "kubernetes_config_map" "otel_collector" {
  metadata {
    name      = "otelcol-config"
    namespace = kubernetes_namespace.concourse.metadata.0.name
  }

  data = {
    "otelcol.yml" = <<-EOF
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:55680
        prometheus:
          config:
            scrape_configs:
            - job_name: 'otel-collector'
              scrape_interval: 30s
              static_configs:
                - targets: ['0.0.0.0:9391']
      exporters:
        jaeger:
          endpoint: ${module.wavefront.tracing_endpoint}
          insecure: true
        logging:
          loglevel: debug
        prometheusremotewrite:
          endpoint: http://${module.wavefront.metrics_endpoint}
      processors:
        attributes/strip_tags:
          actions:
          - key: telemetry.sdk.name
            action: delete
          - key: telemetry.sdk.language
            action: delete
          - key: instrumentation.name
            action: delete
        attributes/insert_cluster:
          actions:
          - key: cluster
            action: insert
            value: ${module.concourse_dispatcher_address.dns_address}
        metricstransform/insert_url:
          transforms:
          - include: .*
            match_type: regexp
            action: update
            operations:
              - action: add_label
                new_label: url
                new_value: ${module.concourse_dispatcher_address.dns_address}
      service:
        pipelines:
          traces:
            receivers:
            - otlp
            processors:
            - attributes/strip_tags
            - attributes/insert_cluster
            exporters:
            - jaeger
          metrics:
            receivers:
            - prometheus
            processors:
            - metricstransform/insert_url
            exporters:
            - prometheusremotewrite
      EOF
  }
}

