resource "kubernetes_namespace" "boarding_pass" {
  depends_on = [
    module.cluster
  ]

  metadata {
    name = "boarding-pass"
  }
}

resource "kubernetes_deployment" "boarding_pass" {
  metadata {
    name      = "boarding-pass"
    namespace = kubernetes_namespace.boarding_pass.id
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "boarding-pass"
      }
    }

    template {
      metadata {
        labels = {
          app = "boarding-pass"
        }
      }

      spec {
        container {
          image = "gcr.io/cf-concourse-production/boarding-pass"
          name  = "boarding-pass"
        }
      }
    }
  }
}

resource "kubernetes_service" "boarding_pass" {
  metadata {
    name      = "boarding-pass"
    namespace = kubernetes_namespace.boarding_pass.id
  }

  spec {
    selector = {
      app = "boarding-pass"
    }

    port {
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = module.boarding_pass_address.address
  }
}
