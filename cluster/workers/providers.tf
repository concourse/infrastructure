terraform {
  backend "pg" {
    # Set env vars PGUSER and PGPASSWORD to access the state file
    conn_str    = "postgres://postgres/terraform_backend?sslmode=disable"
    schema_name = "concourse_worker"
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}
