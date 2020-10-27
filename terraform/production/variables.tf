variable "credentials" {
  type        = string
  description = "GCP key"
}

variable "datadog_api_key" {
  type        = string
  description = "datadog API key to push metrics to datadog"
}

variable "datadog_app_key" {
  type        = string
  description = "datadog app key to  create/destroy dashboards"
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
  default     = "ci-test"
}

variable "prometheus_port" {
  description = "The port on which to listen to expose Prometheus metrics."
  default     = 9391
}
