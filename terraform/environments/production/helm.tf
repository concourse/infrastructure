provider "helm" {
  kubernetes = {
    host = "https://${module.cluster.endpoint}"

    token = data.google_client_config.provider.access_token

    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  }
}

provider "helm" {
  alias = "k8s_topgun"

  kubernetes = {
    host = "https://${module.k8s_topgun_cluster.endpoint}"

    token = data.google_client_config.provider.access_token

    cluster_ca_certificate = base64decode(module.k8s_topgun_cluster.cluster_ca_certificate)
  }
}
