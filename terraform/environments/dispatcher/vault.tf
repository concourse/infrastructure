module "vault" {
  source = "${var.dependencies_path}/vault"

  gcp_service_account_id           = "dispatcher-vault"
  gcp_service_account_display_name = "Dispatcher Vault"
  gcp_service_account_description  = "Used to operate Vault in our Dispatcher cluster."

  bucket_name = "concourse-dispatcher-vault"

  depends_on = [
    module.cluster.node_pools
  ]
}
