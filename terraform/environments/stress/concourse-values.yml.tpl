image: ${image_repo}
imageDigest: ${image_digest}

postgresql:
  enabled: false

web:
  annotations:
    rollingUpdate: "1"
  replicas: 2
  nodeSelector:
    cloud.google.com/gke-nodepool: generic
  env:
  - name: CONCOURSE_X_FRAME_OPTIONS
    value: ""

  resources:
    requests:
      cpu: 1000m
      memory: 1Gi
    limits:
      cpu: 1500m
      memory: 1Gi

  service:
    api:
      type: LoadBalancer
      loadBalancerIP: ${lb_address}
    workerGateway:
      type: LoadBalancer
      loadBalancerIP: ${lb_address}

  sidecarContainers:
    - name: otel-collector
      image: otel/opentelemetry-collector-contrib:0.15.0
      args: ['--config=/etc/config/otelcol.yml']
      volumeMounts:
        - name: otelcol-config
          mountPath: /etc/config

  additionalVolumes:
    - name: otelcol-config
      configMap:
        name: ${otelcol_config_map_name}

worker:
 enabled: false

concourse:
  web:
    logLevel: debug
    auth:
      mainTeam:
        localUser: admin
    externalUrl: ${external_url}
    bindPort: 80
    clusterName: ${cluster_name}
    containerPlacementStrategy: fewest-build-containers
    enableGlobalResources: true
    encryption: { enabled: true }
    enableArchivePipeline: true
    kubernetes:
      keepNamespaces: false
      enabled: false
      createTeamNamespaces: false
    vault:
      enabled: true
      url: https://vault.vault.svc.cluster.local:8200
      sharedPath: shared
      authBackend: "cert"
      useCaCert: true
      useAuthParam: false
    letsEncrypt: { enabled: true, acmeURL: "https://acme-v02.api.letsencrypt.org/directory" }
    tls: { enabled: true, bindPort: 443 }
    prometheus:
      enabled: true
    postgres:
      host: ${db_ip}
      database: ${db_database}
      sslmode: verify-ca
    tracing:
      serviceName: ${tracing_service_name}
      otlpAddress: 127.0.0.1:55680
      otlpUseTls: false

secrets:
  postgresUser: ${db_user}
  postgresPassword: ${db_password}
  postgresCaCert: ${db_ca_cert}
  postgresClientCert: ${db_cert}
  postgresClientKey: ${db_private_key}

  encryptionKey: ${encryption_key}
  localUsers: ${local_users}

  hostKey: ${host_key}
  workerKeyPub: ${worker_key_pub}

  sessionSigningKey: ${session_signing_key}

  vaultCaCert: ${vault_ca_cert}
  vaultClientCert: ${vault_client_cert}
  vaultClientKey: ${vault_client_private_key}
