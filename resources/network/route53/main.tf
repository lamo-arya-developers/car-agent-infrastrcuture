
# Terraform creates and owns the hosted zone
# After first apply: copy the NS records from the AWS Console and set them at your domain registrar
resource "aws_route53_zone" "main" {
  name = var.domain_name
}
