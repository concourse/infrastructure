#!/bin/bash

function generate_keys {
  head -c 32 /dev/random | xxd -p | tr -d '\n' > key
  head -c 16 /dev/urandom | xxd -p | tr -d '\n' > iv

  gcloud kms encrypt \
    --key projects/cf-concourse-production/locations/global/keyRings/production-vault-unseal-kr/cryptoKeys/production-vault-unseal-key \
    --plaintext-file key \
    --ciphertext-file key.enc
}

function rotate_keys {
  decrypt
  generate_keys
  encrypt
}

function decrypt {
  gcloud kms decrypt \
    --key projects/cf-concourse-production/locations/global/keyRings/production-vault-unseal-kr/cryptoKeys/production-vault-unseal-key \
    --plaintext-file key \
    --ciphertext-file key.enc

  openssl enc -d -aes-256-cbc \
    -K $(cat key) -iv $(cat iv) \
    -in secrets.json.enc \
    -out secrets.json
}

function encrypt {
  gcloud kms decrypt \
    --key projects/cf-concourse-production/locations/global/keyRings/production-vault-unseal-kr/cryptoKeys/production-vault-unseal-key \
    --plaintext-file key \
    --ciphertext-file key.enc

  openssl enc -e -aes-256-cbc \
    -K $(cat key) -iv $(cat iv) \
    -in secrets.json.enc \
    -out secrets.json
}

function pack {
  encrypt
  tar -cf data.tar key.enc iv secrets.json.enc
}
