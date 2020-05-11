terraform {
  backend "gcs" {
    credentials = var.gcp_credentials
    bucket      = var.gcs_bucket
    prefix      = var.gcs_bucket_prefix
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