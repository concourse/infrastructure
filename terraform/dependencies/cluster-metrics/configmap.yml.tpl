receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: kubernetes-nodes-cadvisor
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: true
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs: [{role: node}]

          relabel_configs:
            - target_label: __address__
              replacement: kubernetes.default.svc:443
            - source_labels: [__meta_kubernetes_node_name]
              target_label: __metrics_path__
              # Need $$ to escape the $ (for some reason)
              replacement: /api/v1/nodes/$$1/proxy/metrics/cadvisor

        - job_name: kubernetes-nodes
          scheme: https
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: true
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs: [{role: node}]
          relabel_configs:
            - target_label: __address__
              replacement: kubernetes.default.svc:443
            - source_labels: [__meta_kubernetes_node_name]
              target_label: __metrics_path__
              # Need $$ to escape the $ (for some reason)
              replacement: /api/v1/nodes/$$1/proxy/metrics
exporters:
  logging:
    loglevel: debug
  prometheusremotewrite:
    endpoint: http://${metrics_endpoint}
processors:
  metricstransform/insert_url:
    transforms:
    - include: .*
      match_type: regexp
      action: update
      operations:
        - action: add_label
          new_label: url
          new_value: ${url}
service:
  pipelines:
    metrics:
      receivers:
      - prometheus
      processors:
      - metricstransform/insert_url
      exporters:
      - prometheusremotewrite


