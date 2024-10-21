variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "You can get a new copy of this key from the Tailscale web console when adding a device. https://login.tailscale.com/admin/settings/keys"
}

variable "image_name" {
  type        = string
  description = "Name of an image at docker.io/concourse/*"
}

variable "image_tag" {
  type        = string
  description = "A tag for the docker.io/concourse/* image"
}

variable "worker_private_key" {
  type        = string
  sensitive   = true
  description = "Workers' private key that it will use to authenticate to the Web nodes"
}

variable "tsa_host_public_key" {
  type        = string
  sensitive   = true
  description = "The public key that the Web nodes are using for mutual TLS"
}
