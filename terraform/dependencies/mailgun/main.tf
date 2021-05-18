data "google_dns_managed_zone" "main" {
  name = var.dns_zone
}

resource "google_dns_record_set" "mailgun_mx" {
  name = data.google_dns_managed_zone.main.dns_name
  type = "MX"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.main.name

  rrdatas = [
    "10 mxa.mailgun.org",
    "10 mxb.mailgun.org"
  ]
}

resource "google_dns_record_set" "mailgun_verification" {
  name = data.google_dns_managed_zone.main.dns_name
  type = "TXT"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.main.name

  rrdatas = [
    "v=spf1 include:mailgun.org ~all"
  ]
}

resource "google_dns_record_set" "mailgun_verification_domainkey" {
  name = "krs._domainkey.${data.google_dns_managed_zone.main.dns_name}"
  type = "TXT"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.main.name

  rrdatas = [
    var.verification
  ]
}

resource "google_dns_record_set" "mailgun_tracking" {
  name = "email.${data.google_dns_managed_zone.main.dns_name}"
  type = "CNAME"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.main.name

  rrdatas = [
    "mailgun.org"
  ]
}
