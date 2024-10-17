locals {
  number_of_workers = 5
}

# TODO: add block storage for more disk space? Old workers had 500GB space I believe
resource "hcloud_server" "workers" {
  count = local.number_of_workers

  name        = "concourse-worker-${random_string.main.result}-${count.index}"
  image       = "fedora-40"
  server_type = "ccx23"
  ssh_keys    = ["concourse"]
  location    = "fsn1"
  user_data = templatefile("${path.module}/user_data.sh",
    {
      index = count.index
      # unique_id is to ensure when we bring up new workers that we don't try
      # and use volumes that no longer exist
      unique_id            = random_string.main.result
      tailscale_auth_key   = var.tailscale_auth_key
      image_tag            = var.image_tag
      tsa_host_public_key  = var.tsa_host_public_key
      worker_private_key   = var.worker_private_key
      web_load_balancer_ip = local.web.web_private_ip
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
    "service" : "concourse-worker"
  }
}

data "hcloud_network" "main" {
  name = "main"
}

data "terraform_remote_state" "web" {
  backend = "pg"

  config = {
    bucket                      = "concourse-tf-state"
    key                         = "cluster/web"
    region                      = "fsn1"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://fsn1.your-objectstorage.com"
    }
  }
}

locals {
  web = data.terraform_remote_state.web.outputs
}

resource "random_string" "main" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false

  keepers = {
    image_tag            = var.image_tag
    tsa_host_public_key  = var.tsa_host_public_key
    worker_private_key   = var.worker_private_key
    web_load_balancer_ip = local.web.web_private_ip
    workers              = local.number_of_workers
    user_data            = sha256(file("${path.module}/user_data.sh"))
  }
}
