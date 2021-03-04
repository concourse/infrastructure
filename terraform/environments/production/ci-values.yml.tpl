image: ${image_repo}
imageDigest: ${image_digest}

postgresql:
  enabled: false

web:
  annotations:
    rollingUpdate: "5"
  replicas: 2
  nodeSelector:
    cloud.google.com/gke-nodepool: generic
  env:
  - name: CONCOURSE_X_FRAME_OPTIONS
    value: ""
  # The OTLP tracing stuff aren't on the latest chart yet so we're setting them as env vars
  - name: CONCOURSE_TRACING_SERVICE_NAME
    value: web
  - name: CONCOURSE_TRACING_OTLP_ADDRESS
    value: 127.0.0.1:55680
  - name: CONCOURSE_TRACING_OTLP_USE_TLS
    value: "false"


  resources:
    requests:
      cpu: 1500m
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
    - name: prom-storage-adapter
      image: wavefronthq/prometheus-storage-adapter
      args:
        - -proxy=127.0.0.1
        - -proxy-port=2878
        - -listen=9000
        - -convert-paths=true
    - name: wavefront-proxy
      image: wavefronthq/proxy:9.2
      env:
      - name: WAVEFRONT_URL
        value: "https://vmware.wavefront.com/api/"
      - name: WAVEFRONT_PROXY_ARGS
        # https://github.com/wavefrontHQ/wavefront-proxy/blob/master/pkg/etc/wavefront/wavefront-proxy/wavefront.conf.default
        value: |
          --prefix concourse
          --hostname ci.concourse-ci.org
          --traceJaegerGrpcListenerPorts 14250
          --traceJaegerApplicationName Concourse
      - name: WAVEFRONT_TOKEN
        valueFrom:
          secretKeyRef:
            name: ${wavefront_secret_name}
            key: token
  additionalVolumes:
    - name: otelcol-config
      configMap:
        name: ${otelcol_config_map_name}


persistence:
  worker:
    storageClass: ssd
    size: 750Gi

worker:
  replicas: 8
  nodeSelector:
    cloud.google.com/gke-nodepool: ci-workers
  annotations:
    manual-update-revision: "1"
  terminationGracePeriodSeconds: 120
  updateStrategy:
    rollingUpdate:
      partition: 0
  livenessProbe:
    periodSeconds: 60
    failureThreshold: 10
    timeoutSeconds: 45
  hardAntiAffinity: true
  resources:
    limits:   { cpu: 7500m, memory: 14Gi }
    requests: { cpu: 0m,    memory: 0Gi  }

concourse:
  web:
    auth:
      mainTeam:
        localUser: admin
        github:
          team: concourse:Pivotal
      github:
        enabled: true
    externalUrl: ${external_url}
    bindPort: 80
    clusterName: ci
    containerPlacementStrategy: limit-active-tasks
    maxActiveTasksPerWorker: 5
    streamingArtifactsCompression: zstd
    enableGlobalResources: true
    enableAcrossStep: true
    enablePipelineInstances: true
    encryption:
      enabled: true
    kubernetes:
      keepNamespaces: false
      enabled: false
      createTeamNamespaces: false
    prometheus:
      enabled: true
    vault:
      enabled: true
      url: https://vault.vault.svc.cluster.local:8200
      sharedPath: shared
      authBackend: "cert"
      useCaCert: true
    letsEncrypt: { enabled: true, acmeURL: "https://acme-v02.api.letsencrypt.org/directory" }
    tls: { enabled: true, bindPort: 443 }
    postgres:
      host: ${db_ip}
      database: ${db_database}
      sslmode: verify-ca

  worker:
    rebalanceInterval: 2h
    baggageclaim: { driver: overlay }
    healthcheckTimeout: 40s
    runtime: containerd
    containerd:
      networkPool: "10.254.0.0/16"
      maxContainers: "500"
      restrictedNetworks:
        - "169.254.169.254/32"

secrets:
  githubClientId: ${github_client_id}
  githubClientSecret: ${github_client_secret}

  postgresUser: ${db_user}
  postgresPassword: ${db_password}
  postgresCaCert: ${db_ca_cert}
  postgresClientCert: ${db_cert}
  postgresClientKey: ${db_private_key}

  encryptionKey: ${encryption_key}
  localUsers: ${local_users}

  hostKey: ${host_key}
  hostKeyPub: ${host_key_pub}

  workerKey: ${worker_key}
  workerKeyPub: ${worker_key_pub}

  sessionSigningKey: ${session_signing_key}

  vaultCaCert: ${vault_ca_cert}
  vaultClientCert: ${vault_client_cert}
  vaultClientKey: ${vault_client_private_key}
