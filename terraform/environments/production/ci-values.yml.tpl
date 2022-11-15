image: ${image_repo}
imageDigest: ${image_digest}

postgresql:
  enabled: false

worker:
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
  - name: CONCOURSE_CONTENT_SECURITY_POLICY
    value: ""
  - name: CONCOURSE_ENABLE_RESOURCE_CAUSALITY
    value: "true"

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

concourse:
  web:
    auth:
      mainTeam:
        localUser: admin,svc-security
        github:
          team: concourse:maintainers
      github:
        enabled: true
    externalUrl: ${external_url}
    bindPort: 80
    clusterName: ci
    logLevel: debug
    containerPlacementStrategy: limit-active-tasks
    limitActiveTasks: 5
    streamingArtifactsCompression: zstd
    enableGlobalResources: true
    enableAcrossStep: true
    enablePipelineInstances: true
    enableResourceCausality: true
    baggageclaimResponseHeaderTimeout: 5m
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
      useAuthParam: false
    letsEncrypt: { enabled: true, acmeURL: "https://acme-v02.api.letsencrypt.org/directory" }
    tls: { enabled: true, bindPort: 443 }
    postgres:
      host: ${db_ip}
      database: ${db_database}
      sslmode: verify-ca
  tsa:
    logLevel: debug

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
  workerKeyPub: ${worker_key_pub}

  sessionSigningKey: ${session_signing_key}

  vaultCaCert: ${vault_ca_cert}
  vaultClientCert: ${vault_client_cert}
  vaultClientKey: ${vault_client_private_key}
