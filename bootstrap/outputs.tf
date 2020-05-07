output "greenpeace_terraform_email" {
  value = google_service_account.greenpeace_terraform.email
}

output "greenpeace_bucket_name" {
  value = google_storage_bucket.concourse_greenpeace.name
}