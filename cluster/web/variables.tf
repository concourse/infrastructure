variable "number_of_web_nodes" {
  type    = number
  default = 1
}

variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "You can get a new copy of this key from the Tailscale web console when adding a device. https://login.tailscale.com/admin/settings/keys"
}

variable "db_user" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "image_tag" {
  type        = string
  description = "A tag for the docker.io/concourse/concourse image"
}

variable "github_client_id" {
  type      = string
  sensitive = true
}

variable "github_client_secret" {
  type      = string
  sensitive = true
}

variable "session_signing_key" {
  type        = string
  sensitive   = true
  description = "The session signing key Concourse uses for web sessions"
}

variable "worker_public_keys" {
  type        = string
  sensitive   = true
  description = "Public keys that Concourse should trust for worker auth. The Workers should have the private key that pairs with this public key."
}

variable "tsa_host_key" {
  type        = string
  sensitive   = true
  description = "The private key that Concourse uses for SSH connections to the workers. The workers should trust the public key that pairs with this private key."
}
