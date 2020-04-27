provider "google" {
  project = "cf-concourse-production"
  region  = "us-central1"
}

resource "google_storage_bucket" "concourse_greenpeace" {
  name = "concourse-greenpeace"
  bucket_policy_only = true
}

resource "google_service_account" "greenpeace_terraform_state" {
  account_id   = "greenpeace-terraform-state"
  display_name = "Greenpeace Terraform State"
  description  = "Used by Terraform to store state in the concourse-greenpeace bucket."
}

resource "google_storage_bucket_iam_member" "greenpeace_state_policy" {
  bucket = google_storage_bucket.concourse_greenpeace.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.greenpeace_terraform_state.email}"
}