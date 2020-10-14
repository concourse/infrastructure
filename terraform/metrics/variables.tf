variable "release" {
  default     = "metrics"
  description = "Name of the metrics release"
}

variable "namespace_regex" {
  description = "Regex for which namespaces to include"
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
  description = "The subdomain to prepend to the provided domain. This is where Grafana will be hosted."
}

variable "node_pool" {
  description = "Name of the GKE node pool on which to schedule the prometheus+grafana servers"
}

variable "cert_name" {
  description = "Name of the cert."
}

variable "cert_secret_name" {
  description = "Name of the secret to create containing the TLS cert"
}

variable "issuer_name" {
  description = "Name of the CertManager ClusterIssuer."
}

variable "namespace" {
  description = "K8s namespace to deploy to"
}
