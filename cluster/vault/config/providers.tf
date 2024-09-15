terraform {
  backend "pg" {
    # Set env vars PGUSER and PGPASSWORD to access the state file
    conn_str    = "postgres://postgres/terraform_backend?sslmode=disable"
    schema_name = "vault_config"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

provider "vault" {
  address = "https://vault.tail54de49.ts.net"
  # Set env var VAULT_TOKEN
}
