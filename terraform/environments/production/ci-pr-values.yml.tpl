image: ${image_repo}
imageDigest: ${image_digest}

persistence:
  worker:
    storageClass: ssd
    size: 750Gi

postgresql:
  enabled: false

web:
  enabled: false

worker:
  replicas: 0
  nodeSelector:
    cloud.google.com/gke-nodepool: ci-pr-workers
  annotations:
    manual-update-revision: "1"
  terminationGracePeriodSeconds: 300
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
  worker:
    tag: "pr"
    tsa:
      hosts: ["${host}"]
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
  hostKeyPub: ${host_key_pub}
  workerKey: ${worker_key}
