terraform {
  backend "pg" {
    # Set env vars PGUSER and PGPASSWORD to access the state file
    conn_str    = "postgres://postgres/terraform_backend?sslmode=disable"
    schema_name = "concourse-web"
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}
