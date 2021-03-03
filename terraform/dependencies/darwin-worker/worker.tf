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
        go_package_url       = var.go_package_url
      })
    ]
  }
}
