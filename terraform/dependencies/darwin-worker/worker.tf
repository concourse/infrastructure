variable "macstadium_ip" {
  type = string
}

variable "macstadium_username" {
  type = string
}

variable "macstadium_password" {
  type = string
}

variable "concourse_bundle_url" {
  type    = string
  default = "https://storage.googleapis.com/concourse-artifacts/dev/concourse-6.7.0+dev.461.5e9e2ec33.darwin.amd64.tgz"
}

resource "null_resource" "instance" {
  triggers = {
    ip  = var.macstadium_ip
    url = var.concourse_bundle_url
  }

  connection {
    type     = "ssh"
    host     = var.macstadium_ip
    user     = var.macstadium_username
    password = var.macstadium_password
  }

  provisioner "file" {
    source      = "/tmp/build/put/golang-darwin/*.pkg"
    destination = "/Users/administrator/go.pkg"
  }

  provisioner "file" {
    content     = var.tsa_host_public_key
    destination = "/Users/administrator/keys/tsa-host-key.pub"
  }

  provisioner "file" {
    content     = var.worker_key
    destination = "/Users/administrator/keys/worker-key"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/concourse.sh.tmpl", {
      tsa_host = var.tsa_host,
    })
    destination = "/Users/administrator/concourse.sh"
  }

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/startup.sh.tmpl", {
        password             = var.macstadium_password,
        concourse_bundle_url = var.concourse_bundle_url,
      })
    ]
  }
}
