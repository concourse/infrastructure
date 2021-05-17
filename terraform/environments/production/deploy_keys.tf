locals {
  # To add a new key, just add a unique name to this set.
  # The key will be saved in Vault as: ((deploy_keys.NAME-OF-KEY))
  # You will need to add the public key to the desired repo in
  # https://github.com/concourse/governance/tree/master/repos
  # (the public key is emitted in `terraform outputs`)
  deploy_key_names = toset([
    "ci-repo-push",
  ])

  deploy_key_public_keys = tomap({
    for deploy_key in local.deploy_key_names :
    deploy_key => tls_private_key.deploy_key[deploy_key].public_key_openssh
  })

  deploy_key_private_keys = tomap({
    for deploy_key in local.deploy_key_names :
    deploy_key => tls_private_key.deploy_key[deploy_key].private_key_pem
  })
}

resource "tls_private_key" "deploy_key" {
  for_each    = local.deploy_key_names
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
