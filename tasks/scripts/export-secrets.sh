#!/bin/bash

set -euo pipefail

source greenpeace/scripts/tfhelpers.sh

echo "$GCP_CREDENTIALS_JSON" > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

apt-get update
apt-get install -y unzip jq xxd

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
popd > /dev/null

token="$(cat root-token-enc/root-token.enc | \
  base64 --decode | \
    gcloud kms decrypt \
      --key ${greenpeace_crypto_key_self_link} \
      --ciphertext-file - \
      --plaintext-file -)"

export VAULT_TOKEN="${token}"
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"

export VAULT_BACKEND_MIGRATOR_COMMAND="$(pwd)/vault-backend-migrator/vault-backend-migrator"

greenpeace/scripts/export-secrets

mv greenpeace/sensitive/data.tar secrets/
