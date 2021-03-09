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
  default     = "ci"
}

# This KMS keyring+crypto key are created in bootstrap
variable "greenpeace_kms_region" {
  description = "The cloud provider region where the greenpeace shared key ring is created at."
  default     = "global"
}

variable "greenpeace_kms_kr_name" {
  description = "The name of the greenpeace shared key ring"
  default     = "greenpeace-kr"
}

variable "greenpeace_kms_key_name" {
  description = "The name of the greenpeace shared crypto key"
  default     = "greenpeace-key"
}

variable "greenpeace_kms_key_link" {
  description = "The self link of the greenpeace shared crypto key"
  default     = "projects/cf-concourse-production/locations/global/keyRings/greenpeace-kr/cryptoKeys/greenpeace-key"
}

variable "boarding_pass_image_digest" {
  description = "Digest of the boarding pass image"
}

variable "dutyfree_image_digest" {
  description = "Digest of the dutyfree image"
}

variable "concourse_image_repo" {
  description = "Concourse image repo to use for the ATC and the linux workers"
}

variable "concourse_image_digest" {
  description = "digest for the concourse_image_repo image to use for the ATC and the linux workers"
}

variable "concourse_windows_bundle_url" {
  description = "URL to the Concourse windows .zip file containing the concourse binary. Can be from the concourse-artifacts bucket or from a GitHub release"
}

variable "concourse_darwin_bundle_url" {
  description = "URL to the Concourse darwin .tgz file containing the concourse binary. Can be from the concourse-artifacts bucket or from a GitHub release"
}

variable "macstadium_ip" {
  type = string
}

variable "macstadium_username" {
  type = string
}

variable "macstadium_password" {
  type = string
}

variable "concourse_admin_username" {
  type    = string
  default = "admin"
}

variable "go_windows_package_url" {
  type = string
}

variable "go_darwin_package_url" {
  type = string
}
