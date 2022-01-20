resource "kubernetes_namespace" "baseline" {
  metadata {
    name = "baseline"
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

# Creates the CloudSQL Postgres database to be used by the `baseline`
# Concourse deployment.
#
module "baseline_database" {
  source = "../../dependencies/database"

  name            = "baseline"
  cpus            = "4"
  disk_size_gb    = "150"
  memory_mb       = "5120"
  region          = var.region
  zone            = var.zone
  max_connections = "200"
}

data "template_file" "concourse_baseline_values" {
  template = file("${path.module}/concourse-values.yml.tpl")
  vars = {
    cluster_name = "baseline"

    image_repo   = var.concourse_baseline_image_repo
    image_digest = var.concourse_baseline_image_digest

    lb_address   = module.concourse_baseline_address.address
    external_url = "https://${var.baseline_subdomain}.${var.domain}"

    db_ip          = module.baseline_database.ip
    db_user        = module.baseline_database.user
    db_password    = module.baseline_database.password
    db_database    = module.baseline_database.database
    db_ca_cert     = jsonencode(module.baseline_database.ca_cert)
    db_cert        = jsonencode(module.baseline_database.cert)
    db_private_key = jsonencode(module.baseline_database.private_key)

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

    otelcol_config_map_name = kubernetes_config_map.otel_collector_baseline.metadata.0.name
  }
}

resource "helm_release" "concourse_baseline" {
  namespace  = kubernetes_namespace.baseline.metadata.0.name
  name       = "concourse"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = "14.5.6"

  timeout = 2000

  values = [
    data.template_file.concourse_baseline_values.rendered,
  ]

  depends_on = [
    module.cluster.node_pools,
  ]
}

