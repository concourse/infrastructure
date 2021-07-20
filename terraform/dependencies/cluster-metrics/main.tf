resource "kubernetes_namespace" "cluster_metrics" {
  metadata {
    name = "wavefront-proxy"
  }
}

resource "kubernetes_cluster_role" "cluster_metrics" {
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

resource "kubernetes_service_account" "cluster_metrics" {
  metadata {
    name = "cluster-metrics"
  }
}

resource "kubernetes_cluster_role_binding" "cluster_metrics" {
  metadata {
    name = "cluster-metrics"
  }

  role_ref {
    kind      = "ClusterRole"
    api_group = "rbac.authorization.k8s.io"
    name      = kubernetes_cluster_role.cluster_metrics.id
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cluster_metrics.id
    namespace = kubernetes_namespace.cluster_metrics.id
  }
}

resource "kubernetes_deployment" "cluster_metrics" {
  metadata {
    name      = "cluster-metrics"
    namespace = kubernetes_namespace.cluster_metrics.id
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
        service_account_name = kubernetes_service_account.cluster_metrics.id
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

resource "kubernetes_config_map" "cluster_metrics" {
  metadata {
    name = "wavefront-proxy"
  }

  data = {
    "otelcol.yml" = data.template_file.cluster_metrics_configmap.rendered
  }
}
