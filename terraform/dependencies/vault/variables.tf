variable "project" {
  type    = string
  default = "cf-concourse-production"
}

variable "gcp_service_account_id" {
  type = string
}

variable "gcp_service_account_display_name" {
  type = string
}

variable "gcp_service_account_description" {
  type = string
}

variable "namespace" {
  type    = string
  default = "vault"
}

variable "k8s_service_account_name" {
  type    = string
  default = "vault"
}

variable "bucket_name" {
  type = string
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

variable "vault_root_ca_validity_period" {
  description = "Vault root CA cert expiry time, in hours. 8760 is 1 year btw."
  type        = number
  default     = 8760
}
