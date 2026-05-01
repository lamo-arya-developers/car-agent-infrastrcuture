
output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.main.domain_name
  description = "the CloudFront-assigned domain name (e.g. d1234abcd.cloudfront.net)"
  sensitive   = false
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.main.id
  description = "the CloudFront distribution ID — useful for cache invalidation in CI/CD"
  sensitive   = false
}

output "cloudfront_distribution_arn" {
  value       = aws_cloudfront_distribution.main.arn
  description = "the ARN of the CloudFront distribution"
  sensitive   = true
}
