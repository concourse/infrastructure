output "project" {
  value = var.project
}

output "region" {
  value = var.region
}

output "greenpeace_terraform_email" {
  value = google_service_account.greenpeace_terraform.email
}

output "greenpeace_bucket_name" {
  value = google_storage_bucket.concourse_greenpeace.name
}

output "greenpeace_crypto_key_link" {
  value = google_kms_crypto_key.greenpeace.self_link
}
