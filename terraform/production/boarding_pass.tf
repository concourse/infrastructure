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
      match_labels = {
        app = "boarding-pass"
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
    selector {
      match_labels = {
        app = "boarding-pass"
      }
    }

    type           = "LoadBalancer"
    loadBalancerIP = module.boarding_pass_address.address
  }
}
