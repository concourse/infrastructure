variable "concourse_cert" {
  type = string
  description = "CA cert that vault will use to validate Concourse's cert for authentication"
}

variable "credentials" {
  type = string
  description = "gcp credentials for the pipeline to access gcp"
}

variable "greenpeace_private_key" {
  type = string
  description = "github private key with access to concourse/greenpeace"
}