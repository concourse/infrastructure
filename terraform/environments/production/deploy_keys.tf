locals {
  # To add a new key, just add a unique name to this set
  deploy_key_names = toset([
    "ci-repo-push-key",
  ])

  deploy_key_vault_secrets = [
    for deploy_key in local.deploy_key_names :
    {
      path = deploy_key
      data = {
        value = tls_private_key.deploy_key[deploy_key].private_key_pem
      }
    }
  ]

  deploy_key_public_keys = tomap({
    for deploy_key in local.deploy_key_names :
    deploy_key => tls_private_key.deploy_key[deploy_key].public_key_openssh
  })
}

resource "tls_private_key" "deploy_key" {
  for_each  = local.deploy_key_names
  algorithm = "ECDSA"
}
