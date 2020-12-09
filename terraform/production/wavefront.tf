data "google_secret_manager_secret_version" "wavefront_token" {
  provider = google-beta
  secret   = "production-wavefront_token"
}

resource "kubernetes_secret" "wavefront" {
  metadata {
    name      = "wavefront-proxy"
    namespace = kubernetes_namespace.ci.id
  }

  type = "Opaque"

  data = {
    "token" = data.google_secret_manager_secret_version.wavefront_token.secret_data
  }
}

resource "kubernetes_config_map" "otel_collector" {
  metadata {
    name      = "otelcol-config"
    namespace = kubernetes_namespace.ci.id
  }

  data = {
    "otelcol.yml" = <<EOF
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
    endpoint: localhost:14250
    insecure: true
  logging:
    loglevel: debug
  prometheusremotewrite:
    endpoint: http://localhost:9000/receive
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
      value: ci-test.concourse-ci.org
    # uncomment to disable "intelligent" sampling by wavefront
    # - key: debug
    #   action: insert
    #   value: "true"
  metricstransform/insert_url:
    transforms:
    - include: .*
      match_type: regexp
      action: update
      operations:
        - action: add_label
          new_label: url
          new_value: ci-test.concourse-ci.org
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
