# Reserves an address for `stress.concourse-ci.org` and ties it
# to the given domain.
#
module "concourse_stress_address" {
  source = "../../dependencies/address"

  dns_zone  = var.dns_zone
  subdomain = var.baseline_subdomain
}

# Reserves an address for `baseline.concourse-ci.org` and ties it
# to the given domain.
#
module "concourse_baseline_address" {
  source = "../../dependencies/address"

  dns_zone  = var.dns_zone
  subdomain = var.baseline_subdomain
}
