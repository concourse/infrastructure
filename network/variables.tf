variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "You can get a new copy of this key from the Tailscale web console when adding a device. https://login.tailscale.com/admin/settings/keys"
}
