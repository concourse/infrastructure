provider "google" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "concourse_greenpeace" {
  name                        = "concourse-greenpeace"
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

resource "google_service_account" "greenpeace_terraform" {
  account_id   = "greenpeace-terraform"
  display_name = "Greenpeace Terraform"
  description  = "Used by Terraform to perform updates to our deployments."
}

resource "google_storage_bucket_iam_member" "greenpeace_state_policy" {
  bucket = google_storage_bucket.concourse_greenpeace.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.greenpeace_terraform.email}"
}

resource "google_project_iam_member" "greenpeace_terraform_policy" {
  for_each = {
    "compute"             = "roles/compute.admin"
    "cloudsql"            = "roles/cloudsql.admin"
    "container"           = "roles/container.admin"
    "dns"                 = "roles/dns.admin"
    "networks"            = "roles/servicenetworking.networksAdmin"
    "storage"             = "roles/storage.admin"
    "serviceAccountAdmin" = "roles/iam.serviceAccountAdmin"
    "iamAdmin"            = "roles/resourcemanager.projectIamAdmin"

    # needed for vault
    "kmsAdmin"   = "roles/cloudkms.admin"
    "kmsEncrypt" = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    # needed for creating node pools
    "serviceAccountUser" = "roles/iam.serviceAccountUser"

    "secretManager" = "roles/secretmanager.admin"
  }

  role   = each.value
  member = "serviceAccount:${google_service_account.greenpeace_terraform.email}"
}

resource "google_kms_key_ring" "greenpeace" {
  name     = "greenpeace-kr"
  location = "global"
}

resource "google_kms_crypto_key" "greenpeace" {
  name     = "greenpeace-key"
  key_ring = google_kms_key_ring.greenpeace.self_link

  lifecycle {
    prevent_destroy = true
  }
}
