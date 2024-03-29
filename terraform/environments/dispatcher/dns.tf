# Reserves an address for `dispatcher.concourse-ci.org` and ties it
# to the given domain.
#
module "concourse_dispatcher_address" {
  source = "../../dependencies/address"

  dns_zone  = var.dns_zone
  subdomain = var.subdomain
}
