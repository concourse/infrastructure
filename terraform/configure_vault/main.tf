terraform {
  backend "gcs" {
    bucket = "concourse-greenpeace"
    prefix = "terraform"
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

resource "vault_mount" "concourse" {
  path = "concourse"
  type = "kv"
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

  depends_on = [
    vault_auth_backend.cert,
  ]
}

resource "vault_generic_secret" "greenpeace_gcp_credentials_json" {
  path = "concourse/main/greenpeace_gcp_credentials_json"

  data_json = <<EOT
{
  "value": ${jsonencode(var.credentials)}
}
EOT

  depends_on = [
    vault_mount.concourse,
  ]
}

resource "vault_generic_secret" "greenpeace_private_key" {
  path = "concourse/main/greenpeace_private_key"

  data_json = <<EOT
{
  "value": ${jsonencode(var.greenpeace_private_key)}
}
EOT

  depends_on = [
    vault_mount.concourse,
  ]
}
