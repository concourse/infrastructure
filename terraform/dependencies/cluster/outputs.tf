output "name" {
  value = google_container_cluster.main.name
}

output "zone" {
  value = var.zone
}

output "location" {
  value = google_container_cluster.main.location
}

output "endpoint" {
  value = google_container_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  value = google_container_cluster.main.master_auth[0].cluster_ca_certificate
}

output "node_pools" {
  value = google_container_node_pool.main
}
