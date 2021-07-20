resource "kubernetes_namespace" "main" {
  metadata {
    name = "cluster-metrics"
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
    namespace = kubernetes_namespace.main.metadata.0.name
  }
}

resource "kubernetes_cluster_role_binding" "main" {
  metadata {
    name = "cluster-metrics"
  }

  role_ref {
    kind      = "ClusterRole"
    api_group = "rbac.authorization.k8s.io"
    name      = kubernetes_cluster_role.main.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.main.metadata.0.name
    namespace = kubernetes_namespace.main.metadata.0.name
  }
}

resource "kubernetes_deployment" "main" {
  metadata {
    name      = "cluster-metrics"
    namespace = kubernetes_namespace.main.metadata.0.name
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
        service_account_name = kubernetes_service_account.main.metadata.0.name
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
        volume {
          name = "otel-config"
          config_map {
            name = kubernetes_config_map.main.metadata.0.name
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
    name      = "otel-config"
    namespace = kubernetes_namespace.main.metadata.0.name
  }

  data = {
    "otelcol.yml" = data.template_file.cluster_metrics_configmap.rendered
  }
}
