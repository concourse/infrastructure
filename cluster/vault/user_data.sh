#!/usr/bin/env bash

set -euo pipefail

mkdir /workspace
cd /workspace

sudo hostname vault

curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker

cat << EOF > compose.yml
services:
  vault:
    image: docker.io/hashicorp/vault:latest
    restart: always
    ports:
    - 8200:8200
    logging:
      driver: journald
    environment:
      PGDATA: /var/lib/postgresql/data
EOF

cat << EOF > vault.hcl
storage "postgresql" {
  connection_url = "postgres://${db_user}:${db_password}@postgres:5432/concourse?sslmode=disable"
}

listener "tcp" {
  address = "0.0.0.0:8200"
}

ui = true
api_addr = "http://0.0.0.0:8200"
cluster_name = "Vault"
EOF

# sudo docker compose up -d
