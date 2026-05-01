
output "s3_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "the ARN of the S3 bucket"
  sensitive   = false
}

output "s3_name" {
  value       = aws_s3_bucket.bucket.bucket
  description = "the name of the S3 bucket"
  sensitive   = false
}

output "s3_regional_domain_name" {
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
  description = "the regional domain name of the S3 bucket — used as the CloudFront S3 origin domain"
  sensitive   = false
}
