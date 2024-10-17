data "google_secret_manager_secret_version" "github_client_id" {
  provider = google-beta
  secret   = "dispatcher-concourse-github_client_id"
}

data "google_secret_manager_secret_version" "github_client_secret" {
  provider = google-beta
  secret   = "dispatcher-concourse-github_client_secret"
}

resource "google_secret_manager_secret" "admin_password" {
  provider = google-beta

  secret_id = "dispatcher-concourse-admin_password"

  labels = {
    cluster    = "dispatcher"
    deployment = "concourse"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "admin_password" {
  provider = google-beta

  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin_password.result
}
