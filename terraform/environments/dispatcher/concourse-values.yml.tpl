image: ${image_repo}
imageDigest: ${image_digest}

postgresql:
  enabled: true
  auth:
    username: concourse
    password: ${db_password}
    database: concourse

web:
  annotations:
    rollingUpdate: "4"
  replicas: 1
  nodeSelector:
    cloud.google.com/gke-nodepool: default
  env:
  - name: CONCOURSE_X_FRAME_OPTIONS
    value: ""

  resources:
    requests:
      cpu: 500m
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

worker:
  replicas: 1
  annotations:
    manual-update-revision: "1"
  terminationGracePeriodSeconds: 3600
  livenessProbe:
    periodSeconds: 60
    failureThreshold: 10
    timeoutSeconds: 45
  hardAntiAffinity: true
  runtime: containerd
  containerd:
    networkPool: "10.254.0.0/16"
    maxContainers: "500"
    restrictedNetworks:
      - "169.254.169.254/32"
  resources:
    limits:   { cpu: 1000m, memory: 6Gi }
    requests: { cpu: 0m,    memory: 0Gi  }

concourse:
  web:
    auth:
      mainTeam:
        localUser: admin
        github:
          team: concourse:maintainers
      github:
        enabled: true
    externalUrl: ${external_url}
    bindPort: 80
    clusterName: dispatcher
    containerPlacementStrategy: limit-active-tasks
    maxActiveTasksPerWorker: 5
    enableGlobalResources: true
    enableAcrossStep: true
    enablePipelineInstances: true
    enableResourceCausality: true
    encryption: { enabled: true }
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

  worker:
    rebalanceInterval: 2h
    baggageclaim: { driver: overlay }
    healthcheckTimeout: 40s

persistence:
  worker:
    size: 50Gi

secrets:
  githubClientId: ${github_client_id}
  githubClientSecret: ${github_client_secret}

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
