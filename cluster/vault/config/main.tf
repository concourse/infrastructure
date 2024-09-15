resource "vault_mount" "secrets" {
  path        = "secrets"
  type        = "kv"
  options     = { version = "2" }
  description = "Default secrets engine. Used by Concourse pipelines"
}

resource "vault_kv_secret_backend_v2" "secrets" {
  mount = vault_mount.secrets.path
}

resource "vault_auth_backend" "approle" {
  type = "approle"

  tune {
    max_lease_ttl      = "24h"
    default_lease_ttl  = "24h"
    listing_visibility = "hidden"
  }
}

resource "vault_approle_auth_backend_role" "concourse" {
  backend        = vault_auth_backend.approle.path
  role_name      = "concourse"
  token_policies = ["secrets-readonly"]
}

resource "vault_approle_auth_backend_role_secret_id" "concourse" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.concourse.role_name
}

resource "vault_policy" "secrets_readonly" {
  name   = "secrets-readonly"
  policy = file("secrets-readonly.hcl")
}
