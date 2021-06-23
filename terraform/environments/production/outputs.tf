output "cluster_name" {
  value = module.cluster.name
}

output "cluster_zone" {
  value = module.cluster.location
}

output "project" {
  value = var.project
}

output "ci_concourse_release_name" {
  value = helm_release.ci.name
}

output "ci_namespace" {
  value = kubernetes_namespace.ci.id
}

output "vault_namespace" {
  value = module.vault.namespace
}

output "vault_ca_cert" {
  value     = module.vault.ca_pem
  sensitive = true
}

output "vault_secrets" {
  sensitive = true
  value = [
    {
      path = "concourse/main/concourse"
      data = {
        url      = "https://${var.subdomain}.${var.domain}"
        username = var.concourse_admin_username
        password = random_password.admin_password.result
      }
    },
    {
      path = "concourse/main/greenpeace_gcp_credentials_json"
      data = {
        value = var.credentials
      }
    },
    {
      path = "concourse/main/k8s_topgun",
      data = {
        cluster_name        = module.k8s_topgun_cluster.name,
        cluster_zone        = module.k8s_topgun_cluster.zone,
        cluster_project     = module.k8s_topgun_cluster.zone,
        service_account_key = base64decode(google_service_account_key.k8s_topgun.private_key),
      }
    },
    {
      path = "concourse/main/registry_image_resource_gcr"
      data = {
        repo                = "gcr.io/${var.project}/registry-image-test"
        service_account_key = base64decode(google_service_account_key.registry_image_tester.private_key)
      }
    },
    {
      path = "concourse/main/deploy_keys"
      data = local.deploy_key_private_keys
    },
  ]
}

output "greenpeace_crypto_key_self_link" {
  value = var.greenpeace_kms_key_link
}

output "ci_database_instance_id" {
  value = module.ci_database.instance_id
}

output "ci_database_ip" {
  value = module.ci_database.ip
}

output "ci_database_password" {
  value     = module.ci_database.password
  sensitive = true
}

output "ci_database_ca_cert" {
  value     = module.ci_database.ca_cert
  sensitive = true
}

output "ci_database_cert" {
  value     = module.ci_database.cert
  sensitive = true
}

output "ci_database_private_key" {
  value     = module.ci_database.private_key
  sensitive = true
}

output "deploy_key_public_keys" {
  value = local.deploy_key_public_keys
}
