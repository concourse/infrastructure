output "concourse_role_id" {
  value     = vault_approle_auth_backend_role.concourse.role_id
  sensitive = true
}

output "concourse_secret_id" {
  value     = vault_approle_auth_backend_role_secret_id.concourse.secret_id
  sensitive = true
}
