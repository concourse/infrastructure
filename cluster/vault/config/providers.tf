terraform {
  backend "s3" {
    # Need to set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    bucket                      = "concourse-tf-state"
    key                         = "cluster/vault/config"
    region                      = "fsn1"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://fsn1.your-objectstorage.com"
    }
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
