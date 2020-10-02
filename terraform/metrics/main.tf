resource "helm_release" "cert" {
  namespace = var.namespace
  name   = "${release}-cert"
  chart  = "./charts/cert-manager"
  values = [
    jsonencode({
      "name"       = var.cert_name
      "secretName" = var.cert_secret_name
      "dnsName"    = "${var.subdomain}.${var.domain}"
    })
  ]
}

resource "helm_release" "prometheus" {
  namespace = var.namespace
  name   = "${release}-prometheus"

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

resource "helm_release" "grafana" {
  namespace = var.namespace
  name   = "${release}-grafana"

  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "grafana"
  version    = "4.3.0"

  values = [
    templatefile("${path.module}/grafana-values.yml.tpl", {
      node_pool = var.node_pool
      cert_secret_name = var.cert_secret_name
      dns_name = "${var.subdomain}.${var.domain}"
      lb_address = module.grafana_address.address
    })
  ]
}

resource "kubernetes_config_map" "dashboard" {
  for_each = fileset("${path.module}/dashboards/concourse", "*")

  metadata {
    name = "${var.release}-dashboard-${trimsuffix(each.value.source_path, ".json")}"
    namespace = var.namespace
    labels = {
      "release" = var.release
      "component" = "grafana"
      "grafana/dashboard" = "1"
    }
  }

  data = jsondecode(file(each.value.source_path))
}
