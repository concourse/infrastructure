data "google_compute_zones" "available" {
}

resource "google_compute_address" "windows_worker" {
  name = var.resource_name
}

resource "google_compute_firewall" "windows_worker" {
  name    = "${var.resource_name}-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  target_tags = ["windows-worker"]
}

resource "tls_private_key" "greenpeace_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_instance" "windows_worker" {
  name         = var.resource_name
  machine_type = "custom-8-16384"
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["windows-worker"]

  boot_disk {
    initialize_params {
      image = "windows-server-2004-dc-core-v20201110"
      size  = "256"
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.windows_worker.address
    }
  }

  metadata_startup_script = data.template_file.startup_script.rendered

  metadata = {
    windows-startup-script-ps1 = data.template_file.startup_script.rendered
    ssh-keys = "greenpeace:${tls_private_key.greenpeace_ssh.public_key_openssh}"
  }

  service_account {
    scopes = [
      "logging-write",
      "monitoring"
    ]
  }

  allow_stopping_for_update = true

  shielded_instance_config {
    enable_integrity_monitoring = false
  }

  provisioner "file" {
    source      = "/tmp/build/put/golang-windows/*.msi"
    destination = "C:/go.msi"

    connection {
      type        = "ssh"
      user        = "greenpeace"
      private_key = tls_private_key.private_key_pem
    }
  }
}

data "template_file" "startup_script" {
  template = file("${path.module}/scripts/startup.ps1.tmpl")

  vars = {
    concourse_bundle_url = var.concourse_bundle_url
    tsa_host             = var.tsa_host
    tsa_host_public_key  = var.tsa_host_public_key
    worker_key           = var.worker_key
  }
}
