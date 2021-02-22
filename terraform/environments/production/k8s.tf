provider "kubernetes" {
  host = "https://${module.cluster.endpoint}"

  username = module.cluster.username
  password = module.cluster.password

  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
}
