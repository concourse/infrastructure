variable "credentials" {
  type = string
  description = "GCP key"
}

variable "gcs_bucket" {
  type = string
  description = "GCS bucket name to store the tfstate file"
  default = "concourse-greenpeace"
}

variable "gcs_bucket_prefix" {
  type = string
  description = "Prefix for GCS bucket"
  default = "terraform"
}