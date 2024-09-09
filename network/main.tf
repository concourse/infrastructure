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
