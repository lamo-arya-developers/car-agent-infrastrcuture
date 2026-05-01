
# Certificate covers the apex domain and all subdomains (e.g. www.bilkopshjalpen.se)
# CloudFront requires ACM certificates to be in us-east-1 — ensured by the root provider config
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    # Create the new cert before destroying the old one to avoid downtime during rotation
    create_before_destroy = true
  }
}

# DNS validation CNAME records — one per domain name covered by the cert
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# Waits until ACM confirms the certificate is fully issued before returning
# Downstream resources (CloudFront) depend on this, not on the cert resource directly
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
