resource "kubernetes_namespace" "ci_pr" {
  metadata {
    name = "ci-pr"
  }

  depends_on = [
    module.cluster.node_pools
  ]
}

data "template_file" "ci_pr_values" {
  template = file("${path.module}/ci-pr-values.yml.tpl")
  vars = {
    image_repo   = var.concourse_image_repo
    image_digest = var.concourse_image_digest

    host_key_pub = jsonencode(tls_private_key.host_key.public_key_openssh)
    worker_key   = jsonencode(tls_private_key.worker_key.private_key_pem)

    host = "${helm_release.ci.metadata[0].name}-web-worker-gateway.${kubernetes_namespace.ci.id}.svc.cluster.local:2222"
  }
}

resource "helm_release" "ci_pr" {
  namespace  = kubernetes_namespace.ci_pr.id
  name       = "ci-pr"
  repository = "https://concourse-charts.storage.googleapis.com"
  chart      = "concourse"
  version    = "11.1.0"

  timeout = 1800

  values = [
    data.template_file.ci_pr_values.rendered,
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
        release = helm_release.ci_pr.metadata[0].name
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
            app = "${helm_release.ci.metadata[0].name}-web"
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
