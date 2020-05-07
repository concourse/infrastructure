#!/bin/bash

set -euo pipefail

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
# gcloud config set auth/credential_file_override /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

set -x

apt-get update
apt-get install -y unzip jq

export TF_VERSION=0.12.24
curl -O "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip "terraform_${TF_VERSION}_linux_amd64.zip"
chmod +x terraform
mv terraform /usr/local/bin/

pushd greenpeace/bootstrap/
  gcs_bucket_name="$(terraform output greenpeace_bucket_name)"
popd

pushd production-terraform/
  gcloud container clusters get-credentials "$(terraform output cluster_name)" --zone "$(terraform output cluster_zone)" --project "$(terraform output project)"

  kubectl port-forward service/vault -n "$(terraform output vault_namespace)" 8200:8200 &
  port_forward_pid=$!

  function finish {
    kill $port_forward_pid
  }
  trap finish EXIT

  # TODO: wait until server is up (maybe use timeout + nc + until loop)
  sleep 15

  status_code="$(curl -k -I -s -o /dev/null -w "%{http_code}" https://127.0.0.1:8200/v1/sys/health)"

  case "$status_code" in
  200)
    echo "vault is unsealed and initialized"
    token="$(gsutil cat "gs://${gcs_bucket_name}/vault/root-token.enc" | \
      base64 --decode | \
        gcloud kms decrypt \
          --key $(terraform output vault_crypto_key_self_link) \
          --ciphertext-file - \
          --plaintext-file -)"
    ;;
  501)
    echo "vault is not yet initialized"
    response=$(curl -k -X PUT -H 'Content-Type: application/json' https://127.0.0.1:8200/v1/sys/init -d '{
      "secret_shares": 5,
      "secret_threshold": 3,
      "stored_shares": 1,
      "recovery_shares": 1,
      "recovery_threshold": 1
    }')
    token="$(echo "$response" | jq -r '.root_token')"
    encrypted_token="$(echo -n "$token" | \
      base64 | \
      gcloud kms encrypt \
        --key "$(terraform output vault_crypto_key_self_link)" \
        --plaintext-file - \
        --ciphertext-file -)"
      echo -n "${encrypted_token}" | gsutil cp - "gs://${gcs_bucket_name}/vault/root-token.enc"
      encrypted_init_response="$(echo -n "$response" | \
        base64 | \
        gcloud kms encrypt \
        --key "$(terraform output vault_crypto_key_self_link)" \
        --plaintext-file - \
        --ciphertext-file -)"
      echo -n "${encrypted_init_response}" | gsutil cp - "gs://${gcs_bucket_name}/vault/init-response.json.enc"
    ;;
  *)
    echo "unsupported status code $status_code"
    exit 1
    ;;
  esac
popd

mkdir vault-token
echo "$token" > vault-token/token
