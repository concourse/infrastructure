#!/bin/bash

set -euo pipefail

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

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
