terraform {
  backend "gcs" {
  }
}

provider "vault" {
  # Configured via environment variables:
  # * VAULT_TOKEN
  # * VAULT_ADDR
}

resource "vault_auth_backend" "cert" {
  type = "cert"
}

resource "vault_policy" "concourse" {
  name   = "concourse"
  policy = <<EOT
path "concourse/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_generic_secret" "concourse_cert" {
  path = "auth/cert/certs/concourse"

  data_json = <<EOT
{
  "policies":    ${jsonencode(vault_policy.concourse.name)},
  "certificate": ${jsonencode(var.concourse_cert)}
}
EOT
}

resource "vault_mount" "concourse" {
  path        = "concourse"
  type        = "kv"
}