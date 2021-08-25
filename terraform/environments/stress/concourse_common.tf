resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

resource "random_password" "admin_password" {
  length  = 32
  special = true
}

resource "tls_private_key" "host_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "worker_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "session_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
