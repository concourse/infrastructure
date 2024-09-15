locals {
  network_zone = "eu-central"
}
resource "hcloud_network" "main" {
  name     = "main"
  ip_range = "10.6.0.0/16"
}

resource "hcloud_network_subnet" "public" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = local.network_zone
  ip_range     = "10.6.1.0/24"
}

resource "hcloud_network_subnet" "private" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = local.network_zone
  ip_range     = "10.6.2.0/24"
}

resource "hcloud_server" "nat" {
  name        = "nat"
  image       = "fedora-40"
  server_type = "cx22"
  ssh_keys    = ["concourse"]
  location    = "fsn1"
  user_data = templatefile("${path.module}/user_data.sh",
    {
      tailscale_auth_key = var.tailscale_auth_key
  })

  network {
    network_id = hcloud_network.main.id
    alias_ips  = []
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

resource "hcloud_network_route" "nat" {
  network_id  = hcloud_network.main.id
  destination = "0.0.0.0/0"
  gateway     = one(hcloud_server.nat.network).ip
}
