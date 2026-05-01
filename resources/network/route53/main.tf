
# Reference the existing hosted zone — Terraform does not manage the zone itself
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}
