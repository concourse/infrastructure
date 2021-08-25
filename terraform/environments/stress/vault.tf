module "vault" {
  source = "../../dependencies/vault"

  gcp_service_account_id           = "stress-vault"
  gcp_service_account_display_name = "Stress Vault"
  gcp_service_account_description  = "Used to operate Vault in our Stress cluster."

  bucket_name = "concourse-stress-vault"

  depends_on = [
    module.cluster.node_pools
  ]
}

