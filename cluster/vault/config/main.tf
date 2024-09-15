resource "vault_mount" "secrets" {
  path        = "secrets"
  type        = "kv"
  options     = { version = "2" }
  description = "Default secrets engine. Used by Concourse pipelines"
}

resource "vault_kv_secret_backend_v2" "secrets" {
  mount = vault_mount.secrets.path
}
