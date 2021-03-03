# Instantiates the GKE Kubernetes cluster.
#
module "cluster" {
  source = "../../dependencies/cluster"

  name    = "production"
  project = var.project
  region  = var.region
  zone    = var.zone

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
    "ci-workers" = {
      auto_upgrade    = true
      disk_size       = "50"
      disk_type       = "pd-ssd"
      image           = "COS"
      local_ssds      = 0
      machine_type    = "custom-8-16384"
      max             = 10
      min             = 1
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    },
    "ci-pr-workers" = {
      auto_upgrade    = true
      disk_size       = "50"
      disk_type       = "pd-ssd"
      image           = "COS"
      local_ssds      = 0
      machine_type    = "custom-8-16384"
      max             = 5
      min             = 1
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

#module "cert_manager_issuer" {
#  source = "../../dependencies/cert_manager_issuer"
#
#  cluster_name = "production"
#  project      = var.project
#
#  depends_on = [
#    module.cluster.node_pools,
#  ]
#}
