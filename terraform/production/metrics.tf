module "cert_manager_issuer" {
  source = "../cert_manager_issuer"

  cluster_name = "production"
  project      = var.project
}
