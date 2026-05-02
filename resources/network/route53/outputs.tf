
output "zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "the ID of the Route53 hosted zone — passed to ACM for DNS validation and to CloudFront for the alias record"
  sensitive   = false
}

output "zone_name" {
  value       = aws_route53_zone.main.name
  description = "the fully qualified domain name of the hosted zone"
  sensitive   = false
}
