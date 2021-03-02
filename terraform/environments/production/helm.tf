provider "helm" {
  kubernetes {
    host = "https://${module.cluster.endpoint}"

    username = module.cluster.username
    password = module.cluster.password

    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  }
}

provider "helm" {
  alias = "k8s_topgun"

  kubernetes {
    host = "https://${module.k8s_topgun_cluster.endpoint}"

    username = module.k8s_topgun_cluster.username
    password = module.k8s_topgun_cluster.password

    cluster_ca_certificate = base64decode(module.k8s_topgun_cluster.cluster_ca_certificate)
  }
}
