#!/usr/bin/env bash

set -euo pipefail

sudo hostname "worker-${unique_id}-${index}"

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
cat << EOF > worker_key
${worker_private_key}
EOF

cat << EOF > tsa_host_key.pub
${tsa_host_public_key}
EOF

cd /workspace

cat << EOF > compose.yml
services:
  web:
    image: docker.io/concourse/concourse:${image_tag}
    command: worker
    privileged: true
    restart: unless-stopped
    logging:
      driver: journald
    stop_signal: SIGUSR2
    volumes:
    - /workspace/keys:/concourse-keys
    environment:
      CONCOURSE_RUNTIME: containerd
      CONCOURSE_TSA_PUBLIC_KEY: /concourse-keys/tsa_host_key.pub
      CONCOURSE_TSA_WORKER_PRIVATE_KEY: /concourse-keys/worker_key
      CONCOURSE_TSA_HOST: ${web_load_balancer_ip}:2222
      CONCOURSE_BIND_IP: 0.0.0.0
      CONCOURSE_BAGGAGECLAIM_BIND_IP: 0.0.0.0
      CONCOURSE_BAGGAGECLAIM_DRIVER: overlay
      CONCOURSE_CONTAINERD_DNS_SERVER: "1.1.1.1"
EOF

sudo docker compose up -d
