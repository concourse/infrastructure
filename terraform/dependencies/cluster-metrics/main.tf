resource "kubernetes_namespace" "main" {
  metadata {
    name = "wavefront-proxy"
  }
}

resource "kubernetes_cluster_role" "main" {
  metadata {
    name = "cluster-metrics"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes", "node/proxy", "node/metrics", "services", "endpoints", "pods", "ingresses", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses/status", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

resource "kubernetes_service_account" "main" {
  metadata {
    name      = "cluster-metrics"
    namespace = kubernetes_namespace.main.id
  }
}

resource "kubernetes_cluster_role_binding" "main" {
  metadata {
    name = "cluster-metrics"
  }

  role_ref {
    kind      = "ClusterRole"
    api_group = "rbac.authorization.k8s.io"
    name      = kubernetes_cluster_role.main.id
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.main.id
    namespace = kubernetes_namespace.main.id
  }
}

resource "kubernetes_deployment" "main" {
  metadata {
    name      = "cluster-metrics"
    namespace = kubernetes_namespace.main.id
    labels = {
      app = "cluster_metrics"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "cluster-metrics"
      }
    }

    template {
      metadata {
        labels = {
          app = "cluster-metrics"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.main.id
        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector-contrib:0.16.0"
          args = [
            "--config=/etc/config/otelcol.yml",
          ]

          volume_mount {
            name       = "otel-config"
            mount_path = "/etc/config"
          }
        }
      }
    }
  }
}

data "template_file" "cluster_metrics_configmap" {
  template = file("${path.module}/configmap.yml.tpl")
  vars = {
    hostname         = var.hostname
    metrics_endpoint = var.metrics_endpoint
  }
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = "wavefront-proxy"
    namespace = kubernetes_namespace.main.id
  }

  data = {
    "otelcol.yml" = data.template_file.cluster_metrics_configmap.rendered
  }
}
