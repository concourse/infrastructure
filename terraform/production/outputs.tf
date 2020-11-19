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
  value = kubernetes_namespace.vault.id
}

output greenpeace_crypto_key_self_link {
  value = var.greenpeace_kms_key_link
}

output vault_ca_cert {
  value = tls_self_signed_cert.vault_ca.cert_pem
}

output ci_database_instance_id {
  value = module.ci_database.instance_id
}
