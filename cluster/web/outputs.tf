output "web_public_ip" {
  value       = hcloud_load_balancer.main.ipv4
  description = "The public IPv4 that the web nodes are behind."
}

output "web_private_ip" {
  value       = hcloud_load_balancer_network.main.ip
  description = "The private IPv4 that the web nodes are behind. Workers should use this IP to access the web nodes"
}
