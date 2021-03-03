variable "dns_zone" {
  description = "Name of the DNS zone"
  type        = string
}

variable "subdomain" {
  description = "Subdomain under the DNS zone to register"
  type        = string
}

variable "compute_address_name" {
  description = "name for compute address. defaults to subdomain"
  default     = null
}
