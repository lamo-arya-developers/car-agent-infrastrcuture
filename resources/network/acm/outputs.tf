
output "certificate_arn" {
  value       = aws_acm_certificate_validation.cert.certificate_arn
  description = "the ARN of the validated ACM certificate — sourced from the validation resource to ensure the cert is fully issued before CloudFront uses it"
  sensitive   = true
}
