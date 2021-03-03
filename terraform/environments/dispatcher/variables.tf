variable "credentials" {
  type        = string
  description = "GCP key"
}

variable "region" {
  description = "The cloud provider region where the resources created at."
  default     = "us-central1"
}

variable "zone" {
  description = "The cloud provider zone where the resources are created at."
  default     = "us-central1-a"
}

variable "project" {
  description = "The Google GCP project to host the resources."
  default     = "cf-concourse-production"
}

variable "dns_zone" {
  description = "The default DNS zone to use when creating subdomains."
  default     = "concourse-ci-org"
}

variable "domain" {
  description = "The domain name corresponding to the provided dns_zone."
  default     = "concourse-ci.org"
}

variable "subdomain" {
  description = "The subdomain to prepend to the provided domain."
  default     = "dispatcher"
}

variable "concourse_image_repo" {
  description = "Concourse image repo to use for the ATC and the linux workers"
}

variable "concourse_image_digest" {
  description = "digest for the concourse_image_repo image to use for the ATC and the linux workers"
}

variable "concourse_admin_username" {
  type    = string
  default = "admin"
}
