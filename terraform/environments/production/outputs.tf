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
        url      = module.concourse_ci_address.address
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
      path = "concourse/main/kube_config"
      data = {
        value = <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${jsonencode(module.k8s_topgun_cluster.cluster_ca_certificate)}
    server: https://${module.k8s_topgun_cluster.endpoint}
  name: gke_cf-concourse-production_us-central1-a_k8s-topgun
contexts:
- context:
    cluster: gke_cf-concourse-production_us-central1-a_k8s-topgun
    user: concourse
  name: topgun
current-context: topgun
preferences: {}
users:
- name: concourse
  user:
    username: ${jsonencode(module.k8s_topgun_cluster.username)}
    password: ${jsonencode(module.k8s_topgun_cluster.password)}
EOF
      }
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
