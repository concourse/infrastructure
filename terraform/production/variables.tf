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
  default     = "ci-test"
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
