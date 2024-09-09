#!/usr/bin/env bash

set -euo pipefail

mkdir /workspace
cd /workspace

sudo hostname vault

curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf install -y podman podman-compose

cat << EOF > vault.hcl
services:
  postgres:
    image: docker.io/hashicorp/vault:latest
    restart: always
    ports:
    - 8200:8200
    volumes:
    - ./key.pem:/opt/vault/key.pem
    - ./cert.pem:/opt/vault/cert.pem
    logging:
      driver: journald
    environment:
      PGDATA: /var/lib/postgresql/data
      POSTGRES_DB: concourse
      POSTGRES_USER: ${db_user}
      POSTGRES_PASSWORD: ${db_password}
EOF

cat << EOF > vault.hcl
storage "postgresql" {
  connection_url = "postgres://${db_user}:${db_password}@postgres:5432/concourse?sslmode=disable"
}
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/cert.pem"
  tls_key_file = "/opt/vault/key.pem"
}
ui = true
api_addr = "https://0.0.0.0:8200"
cluster_name = "Concourse-OSS"
EOF

openssl req -x509 -newkey rsa:4096 -sha256 -days 1825 -nodes \
  -keyout /workspace/key.pem \
  -out /workspace/cert.pem \
  -subj "/CN=vault"

# sudo podman-compose up -d
