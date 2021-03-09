resource "kubernetes_namespace" "dutyfree" {
  metadata {
    name = "dutyfree"
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

resource "kubernetes_deployment" "dutyfree" {
  metadata {
    name      = "dutyfree"
    namespace = kubernetes_namespace.dutyfree.id
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dutyfree"
      }
    }

    template {
      metadata {
        labels = {
          app = "dutyfree"
        }
      }

      spec {
        container {
          image = "concourse/dutyfree@${var.dutyfree_image_digest}"
          name  = "dutyfree"

          env {
            name = "PORT"
            value = "9090"
          }

          env {
            name = "GH_TOKEN"
            value = var.dutyfree_github_token
          }

          port {
            name = "http"
            container_port = 9090
            protocol = "TCP"
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "dutyfree" {
  metadata {
    name      = "dutyfree"
    namespace = kubernetes_namespace.dutyfree.id
  }

  spec {
    selector = {
      app = "dutyfree"
    }

    port {
      port        = 80
      target_port = 9090
    }

    type             = "LoadBalancer"
    load_balancer_ip = module.dutyfree_address.address
  }
}


# Create the cert outside of k8s and from GCP directly
resource "google_compute_managed_ssl_certificate" "dutyfree" {
  provider = "google-beta"

  name = "dispatcher-dutyfree-ssl"

  managed {
    domains = ["resource-types.concourse-ci.org"]
  }
}

resource "kubernetes_ingress" "dutyfree" {
  metadata {
    name = "dutyfree"
    namespace = kubernetes_namespace.dutyfree.id

    # consume the GCP cert via annotations
    annotations = {
      "ingress.gcp.kubernetes.io/pre-shared-cert"   = google_compute_managed_ssl_certificate.dutyfree.name
      "kubernetes.io/ingress.global-static-ip-name" = module.dutyfree_address.address
      "kubernetes.io/ingress.allow-http"            = "false"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = kubernetes_service.dutyfree.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}
