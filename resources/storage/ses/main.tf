
# Domain identity — verifies bilköpshjälpen.se as a sending domain with Easy DKIM
resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.domain_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

# DKIM CNAME records — must be added to Route53 for AWS to verify domain ownership
# SES generates 3 tokens; each becomes a CNAME that Amazon validates automatically
resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = var.zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

# Contact list — holds all marketing email subscribers
resource "aws_sesv2_contact_list" "main" {
  contact_list_name = var.env == "prod" ? "car-offers" : "car-offers-dev"
  description       = "Bilköpshjälpen subscribers — car offer alerts and marketing emails"
}
