#!/bin/bash

set -euo pipefail

source greenpeace/scripts/vault-secrets.sh

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

apt-get update
apt-get install -y unzip jq

curl -O "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -d /usr/local/bin
chmod +x /usr/local/bin/terraform

pushd greenpeace/bootstrap/ > /dev/null
  gcs_bucket_name="$(terraform output greenpeace_bucket_name)"
  greenpeace_crypto_key_self_link="$(terraform output greenpeace_crypto_key_link)"
popd > /dev/null

pushd terraform/ > /dev/null
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
    printf "\nfetching stored root token from gs://${gcs_bucket_name}/vault/${CLUSTER_NAME}/root-token.enc...\n\n"
    token="$(gsutil cat "gs://${gcs_bucket_name}/vault/${CLUSTER_NAME}/root-token.enc" | \
      base64 --decode | \
        gcloud kms decrypt \
          --key ${greenpeace_crypto_key_self_link} \
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

    printf "\nstoring root token to gs://${gcs_bucket_name}/vault/${CLUSTER_NAME}/root-token.enc...\n"
    token="$(echo "$response" | jq -r '.root_token')"
    encrypted_token="$(echo -n "$token" | \
      gcloud kms encrypt \
        --key "${greenpeace_crypto_key_self_link}" \
        --plaintext-file - \
        --ciphertext-file - | \
          base64)"
      echo -n "${encrypted_token}" | gsutil cp - "gs://${gcs_bucket_name}/vault/${CLUSTER_NAME}/root-token.enc"

      printf "\nstoring full init response to gs://${gcs_bucket_name}/vault/${CLUSTER_NAME}/init-response.json.enc (contains recovery keys)...\n"
      encrypted_init_response="$(echo -n "$response" | \
        gcloud kms encrypt \
        --key "${greenpeace_crypto_key_self_link}" \
        --plaintext-file - \
        --ciphertext-file - | \
          base64)"
      echo -n "${encrypted_init_response}" | gsutil cp - "gs://${gcs_bucket_name}/vault/${CLUSTER_NAME}/init-response.json.enc"
    ;;
  *)
    printf "\nunsupported status code $status_code\n"
    exit 1
    ;;
  esac

  kubectl exec vault-0 -n "$(terraform output vault_namespace)" -- vault login "$token" > /dev/null

  vault_ca_cert="$(terraform output vault_ca_cert)"
popd > /dev/null

export VAULT_TOKEN="${token}"
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"

pushd greenpeace/terraform/configure_vault > /dev/null
  terraform init \
    -backend-config "credentials=${GCP_CREDENTIALS_JSON}"
  terraform workspace select "$CLUSTER_NAME-vault" || terraform workspace new "$CLUSTER_NAME-vault"
  terraform apply \
    -auto-approve \
    -input=false \
    -var "concourse_cert=${vault_ca_cert}" \
    -var "credentials=${GCP_CREDENTIALS_JSON}" \
    -var "greenpeace_private_key=${GREENPEACE_PRIVATE_KEY}"
popd > /dev/null

pushd secrets > /dev/null
  decrypt "${greenpeace_crypto_key_self_link}"
popd

vault-backend-migrator/vault-backend-migrator -import concourse/ -file secrets/secrets.json
