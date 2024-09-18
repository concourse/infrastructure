#!/usr/bin/env bash

set -euo pipefail

sudo hostname concourse-web-${index}

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

# NAT client setup
ip route add default via 10.6.0.1
# Persist NAT setup after reboots
cat <<EOF > /etc/NetworkManager/dispatcher.d/ifup-local
/usr/sbin/ip route add default via 10.6.0.1
EOF
chmod +x /etc/NetworkManager/dispatcher.d/ifup-local

mkdir -p /workspace/keys
cd /workspace/keys
cat << EOF > session_signing_key
${session_signing_key}
EOF

cat << EOF > worker_key.pub
${worker_public_keys}
EOF

cat << EOF > tsa_host_key
${tsa_host_key}
EOF

cd /workspace
lan_ip=$(ip addr show | awk '/inet / {print $2}' | grep '10.6' | tr -d '/32')

cat << EOF > compose.yml
services:
  web:
    image: docker.io/concourse/concourse:${image_tag}
    command: web
    restart: unless-stopped
    logging:
      driver: journald
    ports:
    - 8443:8443
    - 2222:2222
    network_mode: host
    volumes:
    - /workspace/keys:/concourse-keys
    environment:
      CONCOURSE_SESSION_SIGNING_KEY: /concourse-keys/session_signing_key
      CONCOURSE_TSA_AUTHORIZED_KEYS: /concourse-keys/worker_key.pub
      CONCOURSE_TSA_HOST_KEY: /concourse-keys/tsa_host_key

      CONCOURSE_POSTGRES_HOST: postgres
      CONCOURSE_POSTGRES_USER: ${db_user}
      CONCOURSE_POSTGRES_PASSWORD: ${db_password}
      CONCOURSE_POSTGRES_DATABASE: concourse

      CONCOURSE_EXTERNAL_URL: https://ci.concourse-oss.org
      CONCOURSE_ENABLE_LETS_ENCRYPT: "true"
      CONCOURSE_TLS_BIND_PORT: 8443
      CONCOURSE_CLUSTER_NAME: ci
      CONCOURSE_PEER_ADDRESS: "$${lan_ip}"
      CONCOURSE_STREAMING_ARTIFACTS_COMPRESSION: zstd
      CONCOURSE_LOG_LEVEL: debug

      CONCOURSE_GITHUB_CLIENT_ID: "${github_client_id}"
      CONCOURSE_GITHUB_CLIENT_SECRET: "${github_client_secret}"
      CONCOURSE_MAIN_TEAM_GITHUB_TEAM: "concourse:maintainers"

      CONCOURSE_CONTAINER_PLACEMENT_STRATEGY: limit-active-tasks
      CONCOURSE_MAX_ACTIVE_TASKS_PER_WORKER: 2

      CONCOURSE_VAULT_URL: "https://vault.tail54de49.ts.net"
      CONCOURSE_VAULT_PATH_PREFIX: "/secrets"
      CONCOURSE_VAULT_AUTH_BACKEND: "approle"
      CONCOURSE_VAULT_AUTH_PARAM: "role_id:${vault_role_id},secret_id:${vault_secret_id}"

      CONCOURSE_ENABLE_PIPELINE_INSTANCES: "true"
      CONCOURSE_ENABLE_ACROSS_STEP: "true"
      CONCOURSE_ENABLE_GLOBAL_RESOURCES: "true"
      CONCOURSE_ENABLE_REDACT_SECRETS: "true"
      CONCOURSE_ENABLE_RERUN_WHEN_WORKER_DISAPPEARS: "true"
      CONCOURSE_ENABLE_CACHE_STREAMED_VOLUMES: "true"
EOF

sudo docker compose up -d
