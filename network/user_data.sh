#!/usr/bin/env bash

set -euo pipefail

sudo hostname nat

curl -fsSL https://tailscale.com/install.sh | sh

sudo tailscale up --auth-key="${tailscale_auth_key}"
sudo tailscale up --ssh

sudo dnf -y install iptables

iptables -t nat -A POSTROUTING -s '10.6.0.0/16' -o eth0 -j MASQUERADE

# Persist NAT setup after reboots
cat <<EOF > /etc/NetworkManager/dispatcher.d/ifup-local
/usr/sbin/iptables -t nat -A POSTROUTING -s '10.6.0.0/16' -o eth0 -j MASQUERADE
EOF
chmod +x /etc/NetworkManager/dispatcher.d/ifup-local
