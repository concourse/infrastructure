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

variable "concourse_url" {
  type = string
  description = "url to the concourse instance"
}

variable "concourse_username" {
  type = string
  description = "username of the admin user"
}

variable "concourse_password" {
  type = string
  description = "password of the admin user"
}
