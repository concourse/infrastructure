# Resources for integration tests on the registry-image resource (to push to GCR)

resource "google_service_account" "registry_image_tester" {
  account_id   = "registry-image-tester"
  display_name = "Registry Image Tester"
  description  = "Used by the registry-image resource to push to GCR as part of its integration tests."
}

resource "google_project_iam_member" "registry_image_tester_gcr_write" {
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.registry_image_tester.email}"
}

resource "google_service_account_key" "registry_image_tester" {
  service_account_id = google_service_account.registry_image_tester.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
