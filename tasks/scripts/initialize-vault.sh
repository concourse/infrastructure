#!/bin/bash

set -euo pipefail

source greenpeace/scripts/vaulthelpers.sh
source greenpeace/scripts/tfhelpers.sh

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

apt-get update
apt-get install -y unzip jq

curl -O "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -d /usr/local/bin
chmod +x /usr/local/bin/terraform

pushd greenpeace/bootstrap/ > /dev/null
  gcs_bucket_name="$(tfoutput greenpeace_bucket_name)"
  greenpeace_crypto_key_self_link="$(tfoutput greenpeace_crypto_key_link)"
popd > /dev/null

pushd terraform/ > /dev/null
  gcloud container clusters get-credentials "$(tfoutput cluster_name)" --zone "$(tfoutput cluster_zone)" --project "$(tfoutput project)"

  printf "\nport-forwarding the vault service to port 8200...\n"
  kubectl port-forward service/vault -n "$(tfoutput vault_namespace)" 8200:8200 >/dev/null &
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

  kubectl exec vault-0 -n "$(tfoutput vault_namespace)" -- vault login "$token" > /dev/null

  vault_ca_cert="$(tfoutput vault_ca_cert)"
  vault_secrets="$(tfoutput vault_secrets)"
popd > /dev/null

vault_version="$(curl -k -s https://127.0.0.1:8200/v1/sys/health | jq -r '.version')"
curl -O "https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"
unzip "vault_${vault_version}_linux_amd64.zip" -d /usr/local/bin
chmod +x /usr/local/bin/vault

export VAULT_TOKEN="${token}"
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"

# enable cert auth backend
if vault auth list | grep "cert/"; then
  echo "cert auth is already enabled"
else
  vault auth enable cert
fi

# authorize concourse's cert
vault write auth/cert/certs/concourse "policies=concourse" "certificate=${vault_ca_cert}"

# enable secrets packend (kv1)
if vault secrets list | grep "concourse/"; then
  echo "secret backend is already enabled"
else
  vault secrets enable -version=1 -path=concourse kv
fi

# decrypt and import the secrets backup
pushd secrets > /dev/null
  decrypt "${greenpeace_crypto_key_self_link}"
popd
vault-backend-migrator/vault-backend-migrator -import concourse/ -file secrets/secrets.json

# add the terraform created secrets
for row in $(echo "${vault_secrets}" | jq -r '.[] | @base64'); do
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  _jq '.data' | vault write "$(_jq '.path')" -
done
