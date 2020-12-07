#!/bin/bash

set -euo pipefail

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

apt-get update
apt-get install -y jq

ROOT_DIR="$(pwd)"
terraform_output () {
  cat "$ROOT_DIR/terraform/metadata" | jq ".$1"
}

pushd greenpeace/bootstrap/ > /dev/null
  gcs_bucket_name="$(terraform_output greenpeace_bucket_name)"
  greenpeace_crypto_key_self_link="$(terraform_output greenpeace_crypto_key_link)"
popd > /dev/null

pushd terraform/ > /dev/null
  gcloud container clusters get-credentials "$(terraform_output cluster_name)" --zone "$(terraform_output cluster_zone)" --project "$(terraform_output project)"

  printf "\nport-forwarding the vault service to port 8200...\n"
  kubectl port-forward service/vault -n "$(terraform_output vault_namespace)" 8200:8200 >/dev/null &
  port_forward_pid=$!

  function finish {
    kill $port_forward_pid
  }
  trap finish EXIT

  printf "waiting for port 8200 to be listening...\n"
  timeout 30 bash -c 'until echo 2>>/dev/null >>/dev/tcp/127.0.0.1/8200; do sleep 1; done'
popd

token="$(cat root-token-enc/root-token.enc | \
  base64 --decode | \
    gcloud kms decrypt \
      --key ${greenpeace_crypto_key_self_link} \
      --ciphertext-file - \
      --plaintext-file -)"

export VAULT_TOKEN="${token}"
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"

greenpeace/scripts/export-secrets

mv greenpeace/sensitive/data.tar secrets/
