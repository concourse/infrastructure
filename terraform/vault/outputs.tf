output ca_pem {
  value = tls_self_signed_cert.ca.cert_pem
}

output client_cert_pem {
  value = module.client_cert.cert_pem
}

output client_private_key_pem {
  value = module.client_cert.private_key_pem
}

output server_cert_pem {
  value = module.server_cert.cert_pem
}

output server_private_key_pem {
  value = module.server_cert.private_key_pem
}

output namespace {
  value = kubernetes_namespace.vault.id
}
