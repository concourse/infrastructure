#!/usr/bin/env bash

set -euo pipefail

sudo hostname vault

curl -fsSL https://tailscale.com/install.sh | sh

# Enable Caddy to fetch certs from the tailscale network
sudo echo "TS_PERMIT_CERT_UID=caddy" >> /etc/default/tailscaled

sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf -y install vault

cat << EOF > vault.hcl
storage "postgresql" {
  connection_url = "postgres://${db_user}:${db_password}@postgres:5432/vault?sslmode=disable"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file = "/opt/vault/tls/tls.key"
}

ui = true
api_addr = "http://127.0.0.1:8200"
cluster_name = "Vault"
EOF

mv -f vault.hcl /etc/vault.d/vault.hcl

sudo dnf -y install 'dnf-command(copr)'
sudo dnf copr -y enable @caddy/caddy
sudo dnf -y install caddy

cat << EOF > Caddyfile
vault.tail54de49.ts.net {
	reverse_proxy https://127.0.0.1:8200 {
		transport http {
                        tls_insecure_skip_verify
                }
	}
}
EOF

mv -f Caddyfile /etc/caddy/Caddyfile

sudo systemctl enable vault
sudo systemctl start vault

sudo systemctl enable caddy
sudo systemctl start caddy
