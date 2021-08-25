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
    endpoint: ${tracing_endpoint}
    insecure: true
  logging:
    loglevel: debug
  prometheusremotewrite:
    endpoint: http://${tracing_endpoint}
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
      value: ${cluster_url}
  metricstransform/insert_url:
    transforms:
    - include: .*
      match_type: regexp
      action: update
      operations:
        - action: add_label
          new_label: url
          new_value: ${cluster_url}
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
