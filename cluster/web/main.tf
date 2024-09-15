resource "hcloud_server" "main" {
  count = var.number_of_web_nodes

  name        = "concourse-web"
  image       = "fedora-40"
  server_type = "cx22"
  ssh_keys    = ["concourse"]
  location    = "fsn1"
  user_data = templatefile("${path.module}/user_data.sh",
    {
      index                = count.index
      tailscale_auth_key   = var.tailscale_auth_key
      db_user              = var.db_user
      db_password          = var.db_password
      image_tag            = var.image_tag
      github_client_id     = var.github_client_id
      github_client_secret = var.github_client_secret
      vault_role_id        = local.vault_config.concourse_role_id
      vault_secret_id      = local.vault_config.concourse_secret_id
      session_signing_key  = var.session_signing_key
      tsa_host_key         = var.tsa_host_key
      worker_public_keys   = var.worker_public_keys
  })

  network {
    network_id = data.hcloud_network.main.id
    alias_ips  = []
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }

  labels = {
    "service" : "concourse-web"
  }
}

data "hcloud_network" "main" {
  name = "main"
}

data "terraform_remote_state" "vault_config" {
  backend = "pg"

  config = {
    conn_str    = "postgres://postgres/terraform_backend?sslmode=disable"
    schema_name = "vault_config"
  }
}

locals {
  vault_config = data.terraform_remote_state.vault_config.outputs
}

# We can't assign a separate floating IP, so prevent destroying this LB
# so we don't lose the IP
resource "hcloud_load_balancer" "main" {
  name               = "concourse-web"
  load_balancer_type = "lb11"
  location           = "fsn1"
  delete_protection  = true

  algorithm {
    type = "least_connections"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_load_balancer_network" "main" {
  load_balancer_id        = hcloud_load_balancer.main.id
  network_id              = data.hcloud_network.main.id
  enable_public_interface = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_load_balancer_service" "workers" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 2222
  destination_port = 2222

  health_check {
    protocol = "tcp"
    port     = 2222
    timeout  = 15
    interval = 15
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "web" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 8443

  health_check {
    protocol = "tcp"
    port     = 8443
    timeout  = 15
    interval = 15
    retries  = 3
  }
}

resource "hcloud_load_balancer_target" "web" {
  count = var.number_of_web_nodes

  load_balancer_id = hcloud_load_balancer.main.id
  type             = "server"
  server_id        = hcloud_server.main[count.index].id
  use_private_ip   = true

  depends_on = [hcloud_server.main]
}
