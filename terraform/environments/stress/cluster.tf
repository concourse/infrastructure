module "cluster" {
  source = "../../dependencies/cluster"

  name    = "stress"
  project = var.project
  region  = var.region
  zone    = var.zone
  initial_node_count = 21

  release_channel = "REGULAR"

  node_pools = {
    "generic" = {
      auto_upgrade    = true
      disk_size       = "50"
      disk_type       = "pd-ssd"
      image           = "COS"
      local_ssds      = 0
      machine_type    = "n1-standard-8"
      max             = 5
      min             = 1
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    },
    "stress-workers" = {
      auto_upgrade    = true
      disk_size       = "50"
      disk_type       = "pd-ssd"
      image           = "UBUNTU_CONTAINERD"
      local_ssds      = 0
      machine_type    = "custom-8-16384"
      max             = 15
      min             = 0
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    },
    "baseline-workers" = {
      auto_upgrade    = true
      disk_size       = "50"
      disk_type       = "pd-ssd"
      image           = "UBUNTU_CONTAINERD"
      local_ssds      = 0
      machine_type    = "custom-8-16384"
      max             = 15
      min             = 0
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    },
  }
}

resource "kubernetes_storage_class" "ssd" {
  metadata {
    name = "ssd"
  }
  storage_provisioner = "kubernetes.io/gce-pd"
  reclaim_policy      = "Delete"
  parameters = {
    type = "pd-ssd"
  }
  volume_binding_mode = "Immediate"

  depends_on = [
    module.cluster.node_pools
  ]
}

