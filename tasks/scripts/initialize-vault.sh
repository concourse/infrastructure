#!/bin/bash

set -euo pipefail

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
# gcloud config set auth/credential_file_override /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

apt-get update
apt-get install -y unzip jq

curl -O "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
chmod +x terraform
mv terraform /usr/local/bin/

pushd greenpeace/bootstrap/
  gcs_bucket_name="$(terraform output greenpeace_bucket_name)"
popd

pushd production-terraform/
  printf "fetching cluster credentials...\n\n"
  gcloud container clusters get-credentials "$(terraform output cluster_name)" --zone "$(terraform output cluster_zone)" --project "$(terraform output project)"

  printf "port-forwarding the vault service to port 8200...\n\n"
  kubectl port-forward service/vault -n "$(terraform output vault_namespace)" 8200:8200 >/dev/null &
  port_forward_pid=$!

  function finish {
    kill $port_forward_pid
  }
  trap finish EXIT
  
  printf "waiting for port 8200 to be available...\n\n"
  timeout 30 bash -c 'until echo 2>>/dev/null >>/dev/tcp/127.0.0.1/8200; do sleep 1; done'

  printf "checking the status of vault...\n"
  status_code="$(curl -k -I -s -o /dev/null -w "%{http_code}" https://127.0.0.1:8200/v1/sys/health)"

  case "$status_code" in
  200)
    printf "vault is unsealed and initialized\n\n"
    printf "fetching stored root token from GCS (bucket: ${gcs_bucket_name})...\n\n"
    token="$(gsutil cat "gs://${gcs_bucket_name}/vault/root-token.enc" | \
      base64 --decode | \
        gcloud kms decrypt \
          --key $(terraform output vault_crypto_key_self_link) \
          --ciphertext-file - \
          --plaintext-file -)"
    ;;
  501)
    printf "vault is not yet initialized\n\n"
    printf "initializing vault...\n\n"
    response=$(curl -k -X PUT -H 'Content-Type: application/json' https://127.0.0.1:8200/v1/sys/init -d '{
      "secret_shares": 5,
      "secret_threshold": 3,
      "stored_shares": 1,
      "recovery_shares": 1,
      "recovery_threshold": 1
    }')

    printf "storing root token to gs://${gcs_bucket_name}/vault/root-token.enc...\n\n"
    token="$(echo "$response" | jq -r '.root_token')"
    encrypted_token="$(echo -n "$token" | \
      gcloud kms encrypt \
        --key "$(terraform output vault_crypto_key_self_link)" \
        --plaintext-file - \
        --ciphertext-file - | \
          base64)"
      echo -n "${encrypted_token}" | gsutil cp - "gs://${gcs_bucket_name}/vault/root-token.enc"

      printf "storing full init response to gs://${gcs_bucket_name}/vault/init-response.json.enc...\n\n"
      encrypted_init_response="$(echo -n "$response" | \
        gcloud kms encrypt \
        --key "$(terraform output vault_crypto_key_self_link)" \
        --plaintext-file - \
        --ciphertext-file - | \
          base64)"
      echo -n "${encrypted_init_response}" | gsutil cp - "gs://${gcs_bucket_name}/vault/init-response.json.enc"
    ;;
  *)
    printf "unsupported status code $status_code"
    exit 1
    ;;
  esac
popd

echo "$token" > vault-token/token
