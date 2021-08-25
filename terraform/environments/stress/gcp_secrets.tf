resource "google_secret_manager_secret" "admin_password" {
  provider = google-beta

  secret_id = "stress-concourse-admin_password"

  labels = {
    cluster    = "stress"
    deployment = "concourse"
  }

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "admin_password" {
  provider = google-beta

  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin_password.result
}
