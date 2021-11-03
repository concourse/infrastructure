#!/bin/bash

function generate_keys {
  head -c 32 /dev/random | xxd -p | tr -d '\n' > key
  head -c 16 /dev/urandom | xxd -p | tr -d '\n' > iv

  gcloud kms encrypt \
    --key $1 \
    --plaintext-file key \
    --ciphertext-file key.enc
}

function rotate_keys {
  decrypt $1
  generate_keys $1
  encrypt $1
}

# https://console.cloud.google.com/security/kms/ for
# key keyring and location info
function decrypt {
  gcloud kms decrypt \
    --key $1 \
    --keyring $2 \
    --location $3 \
    --plaintext-file key \
    --ciphertext-file key.enc

  openssl enc -d -aes-256-cbc \
    -K $(cat key) -iv $(cat iv) \
    -in secrets.json.enc \
    -out secrets.json
}

function encrypt {
  gcloud kms decrypt \
    --key $1 \
    --plaintext-file key \
    --ciphertext-file key.enc

  openssl enc -e -aes-256-cbc \
    -K $(cat key) -iv $(cat iv) \
    -in secrets.json \
    -out secrets.json.enc
}

function pack {
  encrypt $1
  tar -cf data.tar key.enc iv secrets.json.enc
}

