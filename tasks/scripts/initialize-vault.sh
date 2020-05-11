#!/bin/bash

set -euo pipefail

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

apt-get update
apt-get install -y unzip jq

curl -O "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
chmod +x terraform
mv terraform /usr/local/bin/

pushd greenpeace/bootstrap/ > /dev/null
  gcs_bucket_name="$(terraform output greenpeace_bucket_name)"
popd > /dev/null

pushd production-terraform/ > /dev/null
  gcloud container clusters get-credentials "$(terraform output cluster_name)" --zone "$(terraform output cluster_zone)" --project "$(terraform output project)"

  printf "\nport-forwarding the vault service to port 8200...\n"
  kubectl port-forward service/vault -n "$(terraform output vault_namespace)" 8200:8200 >/dev/null &
  port_forward_pid=$!

  function finish {
    kill $port_forward_pid
  }
  trap finish EXIT
  
  printf "waiting for port 8200 to be listening...\n"
  timeout 30 bash -c 'until echo 2>>/dev/null >>/dev/tcp/127.0.0.1/8200; do sleep 1; done'

  printf "\nchecking the status of vault...\n"
  status_code="$(curl -k -I -s -o /dev/null -w "%{http_code}" https://127.0.0.1:8200/v1/sys/health)"

  case "$status_code" in
  200)
    printf "vault is unsealed and initialized\n"
    printf "\nfetching stored root token from gs://${gcs_bucket_name}/vault/root-token.enc...\n\n"
    token="$(gsutil cat "gs://${gcs_bucket_name}/vault/root-token.enc" | \
      base64 --decode | \
        gcloud kms decrypt \
          --key $(terraform output vault_crypto_key_self_link) \
          --ciphertext-file - \
          --plaintext-file -)"
    ;;
  501)
    printf "vault is not yet initialized\n"
    printf "\ninitializing vault...\n"
    response=$(curl -k -X PUT -H 'Content-Type: application/json' https://127.0.0.1:8200/v1/sys/init -d '{
      "secret_shares": 5,
      "secret_threshold": 3,
      "stored_shares": 1,
      "recovery_shares": 1,
      "recovery_threshold": 1
    }')

    printf "\nstoring root token to gs://${gcs_bucket_name}/vault/root-token.enc...\n"
    token="$(echo "$response" | jq -r '.root_token')"
    encrypted_token="$(echo -n "$token" | \
      gcloud kms encrypt \
        --key "$(terraform output vault_crypto_key_self_link)" \
        --plaintext-file - \
        --ciphertext-file - | \
          base64)"
      echo -n "${encrypted_token}" | gsutil cp - "gs://${gcs_bucket_name}/vault/root-token.enc"

      printf "\nstoring full init response to gs://${gcs_bucket_name}/vault/init-response.json.enc (contains recovery keys)...\n"
      encrypted_init_response="$(echo -n "$response" | \
        gcloud kms encrypt \
        --key "$(terraform output vault_crypto_key_self_link)" \
        --plaintext-file - \
        --ciphertext-file - | \
          base64)"
      echo -n "${encrypted_init_response}" | gsutil cp - "gs://${gcs_bucket_name}/vault/init-response.json.enc"
    ;;
  *)
    printf "\nunsupported status code $status_code\n"
    exit 1
    ;;
  esac

  kubectl exec vault-0 -n "$(terraform output vault_namespace)" -- vault login "$token" > /dev/null
popd > /dev/null

pushd greenpeace/terraform/vault > /dev/null
  export VAULT_TOKEN="${token}"
  export VAULT_ADDR="https://127.0.0.1:8200"
  export VAULT_SKIP_VERIFY="true"

  terraform init \
    -backend-config "credentials=${GCP_CREDENTIALS_JSON}" \
    -backend-config "bucket=concourse-greenpeace" \
    -backend-config "prefix=terraform"
  terraform workspace select production-vault || terraform workspace new production-vault
  terraform apply \
    -auto-approve \
    -input=false
popd > /dev/null