provider "google" {
  project = "cf-concourse-production"
  region  = "us-central1"
}

resource "google_storage_bucket" "concourse_greenpeace" {
  name = "concourse-greenpeace"
  bucket_policy_only = true

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

resource "google_service_account" "greenpeace_terraform" {
  account_id   = "greenpeace-terraform"
  display_name = "Greenpeace Terraform"
  description  = "Used by Terraform to perform updates to our deployments."
}

resource "google_storage_bucket_iam_member" "greenpeace_state_policy" {
  bucket = google_storage_bucket.concourse_greenpeace.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.greenpeace_terraform.email}"
}

resource "google_project_iam_member" "greenpeace_terraform_policy" {
  for_each = {
    "compute" = "roles/compute.admin"
    "cloudsql" = "roles/cloudsql.admin"
    "container" = "roles/container.admin"
    "dns" = "roles/dns.admin"
    "networks" = "roles/servicenetworking.networksAdmin"
    "storage" = "roles/storage.admin"
    "serviceAccountAdmin" = "roles/iam.serviceAccountAdmin"
    "iamAdmin" = "roles/resourcemanager.projectIamAdmin"

    # needed for vault
    "kmsAdmin" = "roles/cloudkms.admin"
    "kmsEncrypt" = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    # needed for creating node pools
    "serviceAccountUser" = "roles/iam.serviceAccountUser"

    "secretManager" = "roles/secretmanager.admin"
  }

  role = each.value
  member = "serviceAccount:${google_service_account.greenpeace_terraform.email}"
}

resource "google_storage_bucket" "vault" {
  name = "concourse-greenpeace-vault"
  bucket_policy_only = true

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

resource "google_storage_bucket_iam_member" "vault" {
  bucket = google_storage_bucket.vault.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.greenpeace_terraform.email}"
}

resource "google_kms_key_ring" "vault" {
  name     = "greenpeace-vault-unseal-kr"
  location = "global"
}

resource "google_kms_crypto_key" "vault" {
  name     = "greenpeace-vault-unseal-key"
  key_ring = google_kms_key_ring.vault.self_link

  # rotate every 30 days
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = true
  }
}
