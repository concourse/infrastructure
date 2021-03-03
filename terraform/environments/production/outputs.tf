output "cluster_name" {
  value = module.cluster.name
}

output "cluster_zone" {
  value = module.cluster.location
}

output "project" {
  value = var.project
}

output "ci_concourse_release_name" {
  value = helm_release.ci.name
}

output "ci_namespace" {
  value = kubernetes_namespace.ci.id
}

output "vault_namespace" {
  value = module.vault.namespace
}

output "vault_ca_cert" {
  value = module.vault.ca_pem
}

output "greenpeace_crypto_key_self_link" {
  value = var.greenpeace_kms_key_link
}

output "ci_database_instance_id" {
  value = module.ci_database.instance_id
}

output "ci_database_ip" {
  value = module.ci_database.ip
}

output "ci_database_password" {
  value     = module.ci_database.password
  sensitive = true
}

output "ci_database_ca_cert" {
  value     = module.ci_database.ca_cert
  sensitive = true
}

output "ci_database_cert" {
  value     = module.ci_database.cert
  sensitive = true
}

output "ci_database_private_key" {
  value     = module.ci_database.private_key
  sensitive = true
}

output "concoure_url" {
  value = module.concourse_ci_address.address
}

output "concourse_admin_username" {
  value = var.concourse_admin_username
}

output "concourse_admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}

output "vault_secrets" {
  sensitive = true
  value = jsonencode([
    {
      path = "concourse/main/concourse"
      data = jsonencode({
        url      = module.concourse_ci_address.address
        username = var.concourse_admin_username
        password = random_password.admin_password.result
      })
    },
    {
      path = "concourse/main/greenpeace_gcp_credentials_json"
      data = jsonencode({
        value = var.credentials
      })
    },
    {
      path = "concourse/main/greenpeace_private_key"
      data = jsonencode({
        value = var.greenpeace_private_key
      })
    },
  ])
}
