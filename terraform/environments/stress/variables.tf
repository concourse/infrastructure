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

variable "stress_subdomain" {
  description = "The subdomain to prepend to the provided domain for the stress deployment."
  default     = "stress"
}

variable "baseline_subdomain" {
  description = "The subdomain to prepend to the provided domain for the stress deployment."
  default     = "baseline"
}

variable "concourse_stress_image_repo" {
  description = "Concourse image repo to use for the ATC and the linux workers for the stress environment"
}

variable "concourse_stress_image_digest" {
  description = "digest for the concourse_image_repo image to use for the ATC and the linux workers for the stress environment"
}

variable "concourse_baseline_image_repo" {
  description = "Concourse image repo to use for the ATC and the linux workers for the baseline environment"
}

variable "concourse_baseline_image_digest" {
  description = "digest for the concourse_image_repo image to use for the ATC and the linux workers for the baseline environment"
}

variable "concourse_chart_version" {
  description = "Concourse Helm chart version to use for the kubernetes deployments for the environment"
}
