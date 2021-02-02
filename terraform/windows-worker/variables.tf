variable "concourse_bundle_url" {
  type        = string
  description = "URL to the Concourse windows .zip file containing the concourse binary. Can be from the concourse-artifacts bucket or from a GitHub release"
}

variable "tsa_host_public_key" {
  type        = string
  description = "Public key of the TSA"
}

variable "worker_key" {
  type        = string
  description = "Private key of the worker"
}
