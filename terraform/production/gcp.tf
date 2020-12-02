terraform {
  backend "gcs" {
    bucket = "concourse-greenpeace"
    prefix = "terraform"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 2"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 2"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "google" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
}

# `google-beta` provides us access to GCP's beta APIs.
# This is particularly needed for GKE-related operations.
# It's also used to access the Secret Manager
#
provider "google-beta" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
}

data "google_client_config" "current" {}
