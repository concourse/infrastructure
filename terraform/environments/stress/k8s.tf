data "google_client_config" "provider" {}

provider "kubernetes" {
  host = "https://${module.cluster.endpoint}"

  token = data.google_client_config.provider.access_token

  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
}
