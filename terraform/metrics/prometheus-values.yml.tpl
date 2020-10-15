pushgateway:
  enabled: false
alertmanager:
  enabled: false
nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true
  nodeSelector: { cloud.google.com/gke-nodepool: "${node_pool}" }

server:
  retention: 60d
  nodeSelector: { cloud.google.com/gke-nodepool: "${node_pool}" }
  persistentVolume:
    enabled: true
    size: 300Gi
    storageClass: ssd
  resources:
    limits:
      cpu: 2000m
      memory: 8Gi
    requests:
      cpu: 2000m
      memory: 8Gi

serverFiles:
  prometheus.yml:
    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090

      - job_name: concourse
        static_configs:
          - targets:
            - ${concourse_prometheus}

      - job_name: kubernetes-service-endpoints
        kubernetes_sd_configs: [{role: endpoints}]
        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: replace
            target_label: __scheme__
            regex: (https?)
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name
          - source_labels: [__meta_kubernetes_pod_node_name]
            action: replace
            target_label: kubernetes_node

      - job_name: kubernetes-nodes-cadvisor
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        kubernetes_sd_configs: [{role: node}]

        metric_relabel_configs:
          - source_labels: [namespace]
            regex: "${namespace_regex}"
            action: keep

        relabel_configs:
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor

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
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$1/proxy/metrics

  rules:
    groups:
    - name: node-exporter-rules
      rules:
      - record: node:node_num_cpu:sum
        expr: count(node_cpu_seconds_total{mode="idle"}) without (cpu,mode)
