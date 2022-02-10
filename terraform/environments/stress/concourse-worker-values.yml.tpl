image: ${image_repo}
imageDigest: ${image_digest}

postgresql:
  enabled: false

web:
  enabled: false

worker:
  replicas: 8
  nodeSelector:
    cloud.google.com/gke-nodepool: ${cluster_name}-workers
  annotations:
    manual-update-revision: "1"
  terminationGracePeriodSeconds: 60
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
    limits:   { cpu: 1000m, memory: 6Gi }
    requests: { cpu: 0m,    memory: 0Gi  }

concourse:
  worker:
    logLevel: debug
    tsa: {hosts: ["${host}"]}
    rebalanceInterval: 2h
    baggageclaim: { driver: overlay }
    healthcheckTimeout: 40s

secrets:
  hostKeyPub: ${host_key_pub}
  workerKey: ${worker_key}
