#module "vault" {
#  source = "../../dependencies/vault"
#
#  gcp_service_account_id           = "production-vault"
#  gcp_service_account_display_name = "Production Vault"
#  gcp_service_account_description  = "Used to operate Vault in our Production cluster."
#
#  bucket_name = "concourse-production-vault"
#
#  depends_on = [
#    module.cluster.node_pools
#  ]
#}
