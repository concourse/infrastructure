resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace
  }
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = tls_private_key.ca.algorithm
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name = "vault_ca"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

module "server_cert" {
  source = "../cert"

  common_name = "vault.${kubernetes_namespace.vault.id}.svc.cluster.local"
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [
    "vault.${kubernetes_namespace.vault.id}.svc.cluster.local",
  ]
  ip_addresses = [
    "127.0.0.1",
  ]

  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
}

module "client_cert" {
  source = "../cert"

  common_name = "concourse"
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]

  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
}

resource "google_service_account" "vault" {
  account_id   = var.gcp_service_account_id
  display_name = var.gcp_service_account_display_name
  description  = var.gcp_service_account_description
}

resource "google_storage_bucket" "vault" {
  name                        = var.bucket_name
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 3
    }
  }
}

resource "google_project_iam_member" "policy" {
  for_each = {
    "kmsAdmin"   = "roles/cloudkms.admin"
    "kmsEncrypt" = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  }

  role   = each.value
  member = "serviceAccount:${google_service_account.vault.email}"
}

resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = google_service_account.vault.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project}.svc.id.goog[${kubernetes_namespace.vault.id}/${var.k8s_service_account_name}]",
  ]
}

resource "google_storage_bucket_iam_member" "policy" {
  bucket = google_storage_bucket.vault.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vault.email}"
}

data "template_file" "values" {
  template = file("${path.module}/values.yml.tpl")
  vars = {
    gcp_project     = var.project
    gcp_region      = var.greenpeace_kms_region
    key_ring_name   = var.greenpeace_kms_kr_name
    crypto_key_name = var.greenpeace_kms_key_name

    ca_cert            = jsonencode(tls_self_signed_cert.ca.cert_pem)
    server_cert        = jsonencode(module.server_cert.cert_pem)
    server_private_key = jsonencode(module.server_cert.private_key_pem)

    gcs_bucket = google_storage_bucket.vault.name

    gcp_serviceaccount = google_service_account.vault.email
  }
}

resource "kubernetes_secret" "server_tls" {
  metadata {
    name      = "vault-server-tls"
    namespace = kubernetes_namespace.vault.id
  }

  data = {
    "vault.ca"  = tls_self_signed_cert.ca.cert_pem
    "vault.crt" = module.server_cert.cert_pem
    "vault.key" = module.server_cert.private_key_pem
  }
}

resource "helm_release" "vault" {
  namespace = kubernetes_namespace.vault.id
  name      = "vault"
  chart     = "../../helm/charts/vault-helm"

  values = [
    data.template_file.values.rendered,
  ]

  depends_on = [
    kubernetes_secret.server_tls,
  ]
}

