variable "name" {
  description = "The name of the issuer. Must be unique to the project."
}

variable "email" {
  description = "The email address to use for issuing."
  default     = "concourse@pivotal.io"
}

variable "project" {
  description = "The Google GCP project on which to create the issuer"
  default     = "cf-concourse-production"
}
