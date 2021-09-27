variable "macstadium_ip" {
  type = string
}

variable "macstadium_username" {
  type = string
}

variable "macstadium_password" {
  type = string
}

variable "concourse_bundle_url" {
  type    = string
  description = "URL to the Concourse darwin .tgz file containing the concourse binary. Can be from the concourse-artifacts bucket or from a GitHub release"
}

variable "tsa_host" {
  type        = string
  description = "Address to the TSA host (e.g. ci.concourse-ci.org:2222)"
}

variable "tsa_host_public_key" {
  type        = string
  description = "Public key of the TSA"
}

variable "worker_key" {
  type        = string
  description = "Private key of the worker"
}

variable "go_package_url" {
  type        = string
  description = "Golang package url"
}

variable "worker_dir" {
  type = string
  description = "Directory where Concourse will store containers and volumes"
}
