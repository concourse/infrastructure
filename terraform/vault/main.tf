terraform {
  backend "gcs" {
  }
}

provider "vault" {
  # Configured via environment variables:
  # * VAULT_TOKEN
  # * VAULT_ADDRESS
}

resource "vault_auth_backend" "cert" {
  type = "cert"
}