output cluster_name {
  value = module.cluster.name
}

output cluster_zone {
  value = module.cluster.location
}

output project {
  value = var.project
}

output vault_namespace {
  value = module.vault.namespace
}

output vault_ca_cert {
  value = module.vault.ca_pem
}
