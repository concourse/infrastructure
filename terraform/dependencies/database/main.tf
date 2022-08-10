# A piece of randomization that gets consumed by the
# `google_sql_database_instance` resources.
#
# This is needed in order to facilitate creating and recreating instances
# without waiting for the whole period that GCP requires to name reusal.
#
#
#
resource "random_id" "instance_name" {
  byte_length = 4
}

resource "google_sql_database_instance" "main" {
  name             = "${var.name}-${random_id.instance_name.hex}"
  region           = var.region
  database_version = "POSTGRES_14"

  settings {
    availability_type = "ZONAL"
    disk_autoresize   = true
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    tier              = "db-custom-${var.cpus}-${var.memory_mb}"

    database_flags {
      name  = "log_min_duration_statement"
      value = "-1"
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    ip_configuration {
      ipv4_enabled = "true"
      require_ssl  = "true"

      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled    = true
      start_time = "23:00"
    }

    location_preference {
      zone = var.zone
    }

    insights_config {
      query_insights_enabled = true
    }
  }
  // set this to "false" if you need to delete the instance
  deletion_protection = true

  lifecycle {
    ignore_changes = [
      # Ignore changes to disk_size, which GCP can autoscale
      settings[0].disk_size,
    ]
  }
}

resource "google_sql_database" "db" {
  name = var.database_name

  instance  = google_sql_database_instance.main.name
  charset   = "UTF8"
  collation = "en_US.UTF8"

  depends_on = [
    google_sql_user.user,
  ]
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "google_sql_user" "user" {
  name = var.user

  instance = google_sql_database_instance.main.name
  password = random_password.password.result
}

resource "google_sql_ssl_cert" "cert" {
  common_name = var.common_name
  instance    = google_sql_database_instance.main.name
}
