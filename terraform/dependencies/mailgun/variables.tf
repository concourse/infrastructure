variable "dns_zone" {
  description = "Name of the DNS zone"
  type        = string
}

variable "verification" {
  description = "Verification domainkey value provided from Mailgun settings"
  type        = string
}
