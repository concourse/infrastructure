resource "helm_release" "cert" {
  namespace = var.namespace
  name   = "${var.release}-cert"
  chart  = "${path.module}/charts/cert-manager"
  values = [
    jsonencode({
      "name"       = var.cert_name
      "secretName" = var.cert_secret_name
      "issuerName" = var.issuer_name
      "dnsName"    = "${var.subdomain}.${var.domain}"
    })
  ]
}

resource "helm_release" "prometheus" {
  namespace = var.namespace
  name   = "${var.release}-prometheus"

  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "prometheus"
  version    = "9.7.2"

  values = [
    templatefile("${path.module}/prometheus-values.yml.tpl", {
      node_pool = var.node_pool
      namespace_regex = var.namespace_regex
    })
  ]
}

# Reserves an address tied to the provided domain.
#
module "grafana_address" {
  source = "../address"

  dns_zone  = var.dns_zone
  subdomain = var.subdomain
}

resource "google_service_account" "grafana" {
  account_id   = "${var.cluster_name}-grafana"
  display_name = "${var.cluster_name}-grafana"
}

resource "google_project_iam_member" "grafana_monitoring" {
  role   = "roles/monitoring.viewer"
  member = "serviceAccount:${google_service_account.grafana.email}"
}

resource "google_service_account_iam_binding" "grafana_workload_identity" {
  service_account_id = google_service_account.grafana.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project}.svc.id.goog[${var.namespace}/${var.release}-grafana]",
  ]
}

resource "helm_release" "grafana" {
  namespace = var.namespace
  name   = "${var.release}-grafana"

  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "grafana"
  version    = "4.3.0"

  values = [
    templatefile("${path.module}/grafana-values.yml.tpl", {
      node_pool = var.node_pool
      cert_secret_name = var.cert_secret_name
      dns_name = "${var.subdomain}.${var.domain}"
      lb_address = module.grafana_address.address
      gcp_service_account_email = google_service_account.grafana.email
    })
  ]
}

resource "kubernetes_config_map" "cloudsql-dashboard" {
  metadata {
    name = "${var.release}-dashboard-cloudsql}"
    namespace = var.namespace
    labels = {
      "release" = var.release
      "component" = "grafana"
      "grafana/dashboard" = "1"
    }
  }

  data = {
    "cloudsql.json" = templatefile("${path.module}/dashboards/concourse/cloudsql.json", {
      "project_name" = var.project
      "instance_id"  = var.cloudsql_instance_id
    })
  }
}
