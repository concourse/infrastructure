output cluster_name {
  value = module.cluster.name
}

output cluster_zone {
  value = module.cluster.location
}

output project {
  value = var.project
}

output ci_concourse_release_name {
  value = helm_release.ci-concourse.name
}

output ci_namespace {
  value = kubernetes_namespace.ci.id
}

output vault_namespace {
  value = module.vault.namespace
}

output vault_ca_cert {
  value = module.vault.ca_pem
}

output greenpeace_crypto_key_self_link {
  value = var.greenpeace_kms_key_link
}

output ci_database_instance_id {
  value = module.ci_database.instance_id
}

output ci_database_ip {
  value = module.ci_database.ip
}

output ci_database_password {
  value     = module.ci_database.password
  sensitive = true
}

output ci_database_ca_cert {
  value     = module.ci_database.ca_cert
  sensitive = true
}

output ci_database_cert {
  value     = module.ci_database.cert
  sensitive = true
}

output ci_database_private_key {
  value     = module.ci_database.private_key
  sensitive = true
}

output ci_url {
  value = module.concourse_ci_address.address
}

output ci_admin_username {
  value = var.concourse_admin_username
}

output ci_admin_password {
  value = random_password.admin_password.result
}
