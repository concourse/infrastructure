output "user" {
  value = google_sql_user.user.name
}

output "password" {
  sensitive = true
  value     = random_password.password.result
}

output "database" {
  value = google_sql_database.db.name
}

output "instance_id" {
  value = google_sql_database_instance.main.name
}

output "ip" {
  value = google_sql_database_instance.main.ip_address.0.ip_address
}

output "ca_cert" {
  sensitive = true
  value     = google_sql_database_instance.main.server_ca_cert.0.cert
}

output "cert" {
  sensitive = true
  value     = google_sql_ssl_cert.cert.cert
}

output "private_key" {
  sensitive = true
  value     = google_sql_ssl_cert.cert.private_key
}
