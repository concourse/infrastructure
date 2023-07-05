image: concourse/concourse-dev
imageDigest: sha256:6a8fe98df6bf8c0a6902f01e1b33f49bbfd308e2384811b1a3ae48dc31bcdfba

postgresql:
  enabled: false

web:
  enabled: false

persistence:
  worker:
    storageClass: ssd
    size: 100Gi

worker:
  replicas: 1
  nodeSelector:
    cloud.google.com/gke-nodepool: ci-workers
  annotations:
    manual-update-revision: "2"
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
    logLevel: debug
    tag: "k8s-topgun"
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
