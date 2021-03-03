resource "kubernetes_namespace" "concourse" {
  metadata {
    name = "concourse"
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "random_password" "admin_password" {
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

data "template_file" "concourse_values" {
  template = file("${path.module}/concourse-values.yml.tpl")
  vars = {
    image_repo   = var.concourse_image_repo
    image_digest = var.concourse_image_digest

    lb_address   = module.concourse_dispatcher_address.address
    external_url = "https://${var.subdomain}.${var.domain}"

    github_client_id     = data.google_secret_manager_secret_version.github_client_id.secret_data
    github_client_secret = data.google_secret_manager_secret_version.github_client_secret.secret_data

    db_password = jsonencode(random_password.db_password.result)

    encryption_key = jsonencode(random_password.encryption_key.result)
    local_users    = jsonencode("admin:${random_password.admin_password.result}")

    host_key     = jsonencode(tls_private_key.host_key.private_key_pem)
    host_key_pub = jsonencode(tls_private_key.host_key.public_key_openssh)

    worker_key     = jsonencode(tls_private_key.worker_key.private_key_pem)
    worker_key_pub = jsonencode(tls_private_key.worker_key.public_key_openssh)

    session_signing_key = jsonencode(tls_private_key.session_signing_key.private_key_pem)

    vault_ca_cert            = jsonencode(module.vault.ca_pem)
    vault_client_cert        = jsonencode(module.vault.client_cert_pem)
    vault_client_private_key = jsonencode(module.vault.client_private_key_pem)
  }
}

resource "helm_release" "dispatcher_concourse" {
  namespace  = kubernetes_namespace.concourse.id
  name       = "concourse"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = "11.1.0"

  timeout = 900

  values = [
    data.template_file.concourse_values.rendered,
  ]

  depends_on = [
    module.cluster.node_pools,
  ]
}
