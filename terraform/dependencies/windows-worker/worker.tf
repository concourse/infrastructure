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

resource "google_compute_instance" "windows_worker" {
  name         = var.resource_name
  machine_type = "custom-8-16384"
  zone         = data.google_compute_zones.available.names[0]
  # tags         = ["windows-worker"]

  boot_disk {
    initialize_params {
      image = "windows-2016-core"
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

}

data "template_file" "startup_script" {
  template = file("${path.module}/scripts/startup.ps1.tmpl")

  vars = {
    concourse_bundle_url = var.concourse_bundle_url
    tsa_host             = var.tsa_host
    tsa_host_public_key  = var.tsa_host_public_key
    worker_key           = var.worker_key
    go_package_url       = var.go_package_url
  }
}
