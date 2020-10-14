resource "google_service_account" "dns_solver" {
  account_id   = "${var.cluster_name}-dns01-solver"
  display_name = "${var.cluster_name}-dns01-solver"
}

resource "google_project_iam_member" "dns_admin_role" {
  role   = "roles/dns.admin"
  member = "serviceAccount:${google_service_account.dns_solver.email}"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}


resource "google_service_account_iam_binding" "dns_solver_workload_identity" {
  service_account_id = google_service_account.dns_solver.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project}.svc.id.goog[${kubernetes_namespace.cert_manager.id}/cert-manager]",
  ]
}

resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  namespace = kubernetes_namespace.cert_manager.id

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.0.2"

  values = [
    jsonencode({
      "installCRDs" = true

      "serviceAccount" = {
        "name" = "cert-manager"
        "annotations" = {
          "iam.gke.io/gcp-service-account" = google_service_account.dns_solver.email
        }
      }
    })
  ]
}

resource "helm_release" "issuer" {
  name  = "${var.cluster_name}-cert-manager"
  chart = "./charts/issuer"
  values = [
    jsonencode({
      "name"       = var.cluster_name
      "email"      = var.email
      "gcpProject" = var.project
    })
  ]
  depends_on = [
    helm_release.cert_manager,
  ]
}
