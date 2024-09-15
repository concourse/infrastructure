#!/usr/bin/env bash

set -euo pipefail

mkdir /workspace
cd /workspace

sudo hostname postgres

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

volume=$(ls /mnt)
volume_dir="/mnt/$volume"
mkdir -p "$volume_dir/data"

cat << EOF > compose.yml
services:
  postgres:
    image: docker.io/library/postgres:latest
    restart: always
    ports:
    - 5432:5432
    volumes:
    - $volume_dir/data:/var/lib/postgresql/data
    - /workspace/vault-init.sql:/docker-entrypoint-initdb.d/vault-init.sql
    logging:
      driver: journald
    environment:
      PGDATA: /var/lib/postgresql/data
      POSTGRES_DB: concourse
      POSTGRES_USER: ${db_user}
      POSTGRES_PASSWORD: ${db_password}
EOF

sudo docker compose up -d
