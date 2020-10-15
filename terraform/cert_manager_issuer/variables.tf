variable "cluster_name" {
  description = "The name of the cluster (e.g. production). Must be unique to the project."
}

variable "email" {
  description = "The email address to use for issuing."
  default     = "concourse@pivotal.io"
}

variable "project" {
  description = "The Google GCP project on which to create the issuer"
  default     = "cf-concourse-production"
}
