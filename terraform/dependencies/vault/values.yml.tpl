global:
  tlsDisable: false
injector:
  enabled: false
server:
  annotations:
    update: "1"
  extraVolumes:
    - type: secret
      name: vault-server-tls
  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-server-tls/vault.ca
    GOOGLE_REGION: global
  standalone:
    enabled: true
    config: |
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
        tls_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
        tls_client_ca_file = "/vault/userconfig/vault-server-tls/vault.ca"
      }

      storage "gcs" {
        bucket = "${gcs_bucket}"
      }

      seal "gcpckms" {
        project    = "${gcp_project}"
        region     = "${gcp_region}"
        key_ring   = "${key_ring_name}"
        crypto_key = "${crypto_key_name}"
      }
  serviceAccount:
    annotations:
      iam.gke.io/gcp-service-account: "${gcp_serviceaccount}"

ca: ${ca_cert}
crt: ${server_cert}
key: ${server_private_key}
