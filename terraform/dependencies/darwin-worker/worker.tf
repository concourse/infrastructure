locals {
  startup_script = templatefile("${path.module}/scripts/startup.sh.tmpl", {
    password             = var.macstadium_password,
    concourse_bundle_url = var.concourse_bundle_url,
    go_package_url       = var.go_package_url
  })
  concourse_startup = templatefile("${path.module}/scripts/concourse.sh.tmpl", {
    tsa_host = var.tsa_host,
  })
}

resource "null_resource" "instance" {
  triggers = {
    ip                = var.macstadium_ip
    trigger           = sha256(local.startup_script)
    concourse-startup = sha256(local.concourse_startup)
  }

  connection {
    type     = "ssh"
    host     = var.macstadium_ip
    user     = var.macstadium_username
    password = var.macstadium_password
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
    content     = local.concourse_startup
    destination = "/Users/administrator/concourse.sh"
  }

  provisioner "remote-exec" {
    inline = [
      local.startup_script
    ]
  }
}
