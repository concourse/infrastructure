resource "kubernetes_namespace" "ci_pr" {
  metadata {
    name = "ci-pr"
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

locals {
  ci_pr_values = templatefile("${path.module}/ci-pr-values.yml.tpl",
    {
      image_repo   = var.concourse_worker_image_repo
      image_digest = var.concourse_worker_image_digest

      host_key_pub = jsonencode(tls_private_key.host_key.public_key_openssh)
      worker_key   = jsonencode(tls_private_key.worker_key.private_key_pem)

      host = "${helm_release.ci.metadata.name}-web-worker-gateway.${kubernetes_namespace.ci.id}.svc.cluster.local:2222"
  })
}

resource "helm_release" "ci_pr" {
  namespace  = kubernetes_namespace.ci_pr.id
  name       = "ci-pr"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = var.concourse_chart_version

  timeout = 1800

  values = [
    local.ci_pr_values,
  ]

  depends_on = [
    module.cluster.node_pools,
  ]
}

resource "kubernetes_network_policy" "ci_pr_only_external" {
  metadata {
    name      = "only-external"
    namespace = kubernetes_namespace.ci_pr.id
  }

  spec {
    pod_selector {
      match_labels = {
        release = helm_release.ci_pr.metadata.name
      }
    }

    egress {
      ports {
        port     = "53"
        protocol = "TCP"
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.ci.id
          }
        }
        pod_selector {
          match_labels = {
            app = "${helm_release.ci.metadata.name}-web"
          }
        }
      }

      to {
        ip_block {
          # allow any out
          cidr = "0.0.0.0/0"
          except = [
            # except internal comms
            "10.0.0.0/8",
          ]
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}
