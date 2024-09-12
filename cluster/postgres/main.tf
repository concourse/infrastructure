resource "hcloud_server" "main" {
  name        = "postgres"
  image       = "fedora-40"
  server_type = "ccx13"
  ssh_keys    = ["concourse"]
  location    = "fsn1"
  user_data = templatefile("${path.module}/user_data.sh",
    {
      tailscale_auth_key = var.tailscale_auth_key
      db_user            = var.db_user
      db_password        = var.db_password
  })

  network {
    network_id = data.hcloud_network.main.id
    alias_ips  = []
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
}

resource "hcloud_volume" "main" {
  name              = "postgres"
  size              = 100
  automount         = true
  format            = "ext4"
  delete_protection = true
  server_id         = hcloud_server.main.id

  lifecycle {
    prevent_destroy = true
  }
}

data "hcloud_network" "main" {
  name = "main"
}
