module "k8s_topgun_cluster" {
  source = "../../dependencies/cluster"

  name    = "k8s-topgun"
  project = var.project
  region  = var.region
  zone    = var.zone

  release_channel = "REGULAR"

  node_pools = {
    "ci-workers" = {
      auto_upgrade    = true
      disk_size       = "20"
      disk_type       = "pd-ssd"
      image           = "COS"
      local_ssds      = 0
      machine_type    = "n1-standard-8"
      max             = 3
      min             = 1
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    },
    "ubuntu" = {
      auto_upgrade    = true
      disk_size       = "100"
      disk_type       = "pd-ssd"
      image           = "Ubuntu"
      local_ssds      = 0
      machine_type    = "n1-highcpu-8"
      max             = 10
      min             = 1
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
      labels = {
        nodeImage = "ubuntu"
      }
    },
    "cos" = {
      auto_upgrade    = true
      disk_size       = "100"
      disk_type       = "pd-ssd"
      image           = "COS"
      local_ssds      = 0
      machine_type    = "n1-highcpu-8"
      max             = 10
      min             = 1
      preemptible     = false
      service_account = null
      extra_oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
      labels = {
        nodeImage = "cos"
      }
    },
  }
}

resource "kubernetes_storage_class" "k8s_topgun_ssd" {
  provider = kubernetes.k8s_topgun

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
    module.k8s_topgun_cluster.node_pools
  ]
}

resource "kubernetes_namespace" "ci_topgun_worker" {
  provider = kubernetes.k8s_topgun

  metadata {
    name = "ci-topgun-worker"
  }

  depends_on = [
    module.k8s_topgun_cluster.node_pools
  ]
}

data "template_file" "ci_topgun_worker_values" {
  template = file("${path.module}/k8s_topgun_worker-values.yml.tpl")
  vars = {
    image_repo   = var.concourse_image_repo
    image_digest = var.concourse_image_digest

    host_key_pub = jsonencode(tls_private_key.host_key.public_key_openssh)
    worker_key   = jsonencode(tls_private_key.worker_key.private_key_pem)

    host = "${var.subdomain}.${var.domain}:2222"
  }
}

resource "helm_release" "k8s_topgun_worker" {
  provider = helm.k8s_topgun

  namespace  = kubernetes_namespace.ci_topgun_worker.id
  name       = "topgun-worker"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = var.concourse_chart_version

  timeout = 1800

  values = [
    data.template_file.ci_topgun_worker_values.rendered,
  ]

  depends_on = [
    module.k8s_topgun_cluster.node_pools,
  ]
}

data "google_iam_role" "container_developer" {
  name = "roles/container.developer"
}

resource "google_project_iam_custom_role" "k8s_topgun" {
  role_id     = "k8s_topgun_role"
  title       = "K8s Topgun Role"
  description = "Role used by k8s topgun service account to create/delete resources in the k8s-topgun cluster."
  permissions = concat(
    data.google_iam_role.container_developer.included_permissions,
    [
      "container.roleBindings.create",
    ]
  )
}

resource "google_service_account" "k8s_topgun" {
  account_id   = "k8s-topgun"
  display_name = "K8s Topgun"
  description  = "Has access to the K8s topgun cluster, used for k8s topgun and k8s smoke tests."
}

resource "google_project_iam_member" "k8s_topgun" {
  for_each = {
    "k8s_topgun" = google_project_iam_custom_role.k8s_topgun.id
  }

  role   = each.value
  member = "serviceAccount:${google_service_account.k8s_topgun.email}"
}

resource "google_service_account_key" "k8s_topgun" {
  service_account_id = google_service_account.k8s_topgun.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
