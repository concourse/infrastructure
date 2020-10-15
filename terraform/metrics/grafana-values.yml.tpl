nodeSelector: { cloud.google.com/gke-nodepool: "${node_pool}" }
enabled: true
livenessProbe:
  httpGet:
    scheme: HTTPS
readinessProbe:
  httpGet:
    scheme: HTTPS
extraSecretMounts:
- name: metrics-tls
  mountPath: /tls
  secretName: "${cert_secret_name}"
  readOnly: true
grafana.ini:
  server:
    protocol: https
    domain: "${dns_name}"
    root_url: "https://${dns_name}"
    cert_file: /tls/tls.crt
    cert_key: /tls/tls.key
  users:
    auto_assign_organization_role: Editor
  auth.anonymous:
    enabled: true
service:
  loadBalancerIP: "${lb_address}"
  port: 443
  type: LoadBalancer
serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: "${gcp_service_account_email}"
sidecar:
  dashboards:
    enabled: true
    label: grafana/dashboard
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: prometheus
      type: prometheus
      access: proxy
      url: http://metrics-prometheus-server
      isDefault: true
    - name: stackdriver
      type: stackdriver
      access: proxy
      jsonData:
        authenticationType: gce
