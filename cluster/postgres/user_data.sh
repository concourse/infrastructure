#!/usr/bin/env bash

set -euo pipefail

mkdir /workspace
cd /workspace

sudo hostname postgres

curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf install -y podman podman-compose

volume=$(ls /mnt)
volume_dir="/mnt/$volume"
mkdir -p "$volume_dir/data"

cat << EOF > vault-init.sql
CREATE TABLE IF NOT EXISTS vault_kv_store (
  parent_path TEXT COLLATE "C" NOT NULL,
  path        TEXT COLLATE "C",
  key         TEXT COLLATE "C",
  value       BYTEA,
  CONSTRAINT pkey PRIMARY KEY (path, key)
);

CREATE INDEX IF NOT EXISTS parent_path_idx ON vault_kv_store (parent_path);
EOF

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

sudo podman-compose up -d
