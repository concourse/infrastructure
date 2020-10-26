image: concourse/dev
# watch-endpoints branch image
imageDigest: sha256:7a704b87c973908f1cf6a2f9eb151d85849bcfe34e5e8a28b4ec44ec63bf5d98

postgresql:
  enabled: false

web:
  annotations:
    rollingUpdate: "4"
  replicas: 1
  nodeSelector:
    cloud.google.com/gke-nodepool: generic-1
  env:
  - name: CONCOURSE_X_FRAME_OPTIONS
    value: ""
  - name: CONCOURSE_ENABLE_WATCH_ENDPOINTS
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

persistence:
  worker:
    storageClass: ssd
    size: 750Gi

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
  env:
  - name: CONCOURSE_GARDEN_NETWORK_POOL
    value: "10.254.0.0/16"
  - name: CONCOURSE_GARDEN_MAX_CONTAINERS
    value: "500"
  - name: CONCOURSE_GARDEN_DENY_NETWORK
    value: "169.254.169.254/32"
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
    letsEncrypt: { enabled: true, acmeURL: "https://acme-v02.api.letsencrypt.org/directory" }
    tls: { enabled: true, bindPort: 443 }
    prometheus:
      enabled: true
      bindPort: ${prometheus_port}
    postgres:
      host: ${db_ip}
      database: ${db_database}
      sslmode: verify-ca
    additionalVolumes:
      - name: dsdsocket
        hostPath:
          path: /var/run/datadog
    additionalVolumeMounts:
      - name: dsdsocket
        mountPath: /var/run/datadog
    sidecarContainers:
      - name: telegraf
        image: telegraf
        volumeMounts:
        - name: dsdsocket
          mountPath: /var/run/datadog
        command:
        - /bin/bash
        - -c
        - |
          echo '
          [[inputs.prometheus]]
            urls = ["http://127.0.0.1:${prometheus_port}"]
            metric_version = 2
            ## TODO: what do the next lines do?
            name_override = "concourse.ci"
            [inputs.prometheus.tags]
              environment = "ci"
          [[outputs.datadog]]
            url = unix:///var/run/datadog/dsd.socket
          ' > /etc/telegraf/telegraf.conf

          exec telegraf

  worker:
    rebalanceInterval: 2h
    baggageclaim: { driver: overlay }
    healthcheckTimeout: 40s

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
