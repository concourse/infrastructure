output "cluster_name" {
  value = module.cluster.name
}

output "cluster_zone" {
  value = module.cluster.location
}

output "project" {
  value = var.project
}

output "vault_namespace" {
  value = module.vault.namespace
}

output "vault_ca_cert" {
  value = module.vault.ca_pem
}

output "vault_secrets" {
  sensitive = true
  value = [
    {
      path = "concourse/main/greenpeace_gcp_credentials_json"
      data = {
        value = var.credentials
      }
    },
  ]
}
