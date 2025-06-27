resource "kubernetes_namespace" "ci" {
  metadata {
    name = "ci"

    labels = {
      name = "ci"
    }
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

resource "kubernetes_namespace" "ci_workers" {
  metadata {
    name = "ci-workers"

    labels = {
      name = "ci-workers"
    }
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

resource "random_password" "admin_password" {
  length  = 32
  special = true
}

resource "random_password" "svc_security_password" {
  length  = 32
  special = true
}

resource "tls_private_key" "host_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "worker_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "session_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Creates the CloudSQL Postgres database to be used by the `ci`
# Concourse deployment.
#
module "ci_database" {
  source = "../../dependencies/database"

  name            = "ci"
  cpus            = "4"
  disk_size_gb    = "150"
  memory_mb       = "5120"
  region          = var.region
  zone            = var.zone
  max_connections = "200"
}

locals {
  ci_values = templatefile("${path.module}/ci-values.yml.tpl",
    {
      image_repo   = var.concourse_web_image_repo
      image_digest = var.concourse_web_image_digest

      lb_address   = module.concourse_ci_address.address
      external_url = "https://${var.subdomain}.${var.domain}"

      github_client_id     = data.google_secret_manager_secret_version.github_client_id.secret_data
      github_client_secret = data.google_secret_manager_secret_version.github_client_secret.secret_data

      db_ip          = module.ci_database.ip
      db_user        = module.ci_database.user
      db_password    = module.ci_database.password
      db_database    = module.ci_database.database
      db_ca_cert     = jsonencode(module.ci_database.ca_cert)
      db_cert        = jsonencode(module.ci_database.cert)
      db_private_key = jsonencode(module.ci_database.private_key)

      encryption_key = jsonencode(random_password.encryption_key.result)
      local_users    = jsonencode("${var.concourse_admin_username}:${random_password.admin_password.result},${var.concourse_svc_security_username}:${random_password.svc_security_password.result}")

      host_key     = jsonencode(tls_private_key.host_key.private_key_pem)
      host_key_pub = jsonencode(tls_private_key.host_key.public_key_openssh)

      worker_key     = jsonencode(tls_private_key.worker_key.private_key_pem)
      worker_key_pub = jsonencode(tls_private_key.worker_key.public_key_openssh)

      session_signing_key = jsonencode(tls_private_key.session_signing_key.private_key_pem)

      vault_ca_cert            = jsonencode(module.vault.ca_pem)
      vault_client_cert        = jsonencode(module.vault.client_cert_pem)
      vault_client_private_key = jsonencode(module.vault.client_private_key_pem)
  })
}

resource "helm_release" "ci" {
  namespace  = kubernetes_namespace.ci.id
  name       = "ci"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = var.concourse_chart_version

  values = [
    local.ci_values,
  ]

  depends_on = [
    module.cluster.node_pools,
  ]
}

locals {
  ci_workers_values = templatefile("${path.module}/ci-workers-values.yml.tpl",
    {
      image_repo   = var.concourse_worker_image_repo
      image_digest = var.concourse_worker_image_digest

      host_key_pub = jsonencode(tls_private_key.host_key.public_key_openssh)
      worker_key   = jsonencode(tls_private_key.worker_key.private_key_pem)

      host = "${helm_release.ci.metadata.name}-web-worker-gateway.${kubernetes_namespace.ci.id}.svc.cluster.local:2222"
  })
}

resource "helm_release" "ci_workers" {
  namespace  = kubernetes_namespace.ci_workers.id
  name       = "ci-workers"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = var.concourse_chart_version

  timeout = 1800

  values = [
    local.ci_workers_values,
  ]

  depends_on = [
    module.cluster.node_pools,
  ]
}

module "windows_worker" {
  source = "../../dependencies/windows-worker"

  resource_name        = "windows-worker-ci"
  concourse_bundle_url = var.concourse_windows_bundle_url
  tsa_host             = "${module.concourse_ci_address.address}:2222"
  tsa_host_public_key  = tls_private_key.host_key.public_key_openssh
  worker_key           = tls_private_key.worker_key.private_key_pem
  go_package_url       = var.go_windows_package_url
}
