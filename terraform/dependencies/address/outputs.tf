output "address" {
  value = google_compute_address.main.address
}

output "name" {
  value = google_compute_address.main.name
}

output "dns_address" {
  value = trimsuffix(google_dns_record_set.main.name, ".")
}
