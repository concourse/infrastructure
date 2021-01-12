resource "kubernetes_namespace" "boarding_pass" {
  depends_on = [
    module.cluster
  ]

  metadata {
    name = "boarding-pass"
  }
}

resource "kubernetes_secret" "boarding_pass" {
  metadata {
    name      = "htpasswd"
    namespace = kubernetes_namespace.boarding_pass.id
  }

  type = "Opaque"

  data = {
    # Regular workstation password for basic auth
    ".htpasswd" = "concourse:SNIPPED"
  }
}

resource "kubernetes_config_map" "boarding_pass" {
  metadata {
    name      = "content"
    namespace = kubernetes_namespace.boarding_pass.id
  }

  binary_data = {
    for file in fileset(path.module, "/../../../static-content/**/*") :
    trimprefix(file, "../../../static-content/") => filebase64(file)
  }
}
