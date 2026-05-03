output "s3_arn" {
  description = "the ARN of the profile pictures S3 bucket"
  value       = aws_s3_bucket.profile_pictures.arn
  sensitive   = false
}

output "s3_name" {
  description = "the name of the profile pictures S3 bucket"
  value       = aws_s3_bucket.profile_pictures.bucket
  sensitive   = false
}
