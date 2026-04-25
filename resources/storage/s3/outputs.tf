output "s3_arn" {
  value = aws_s3_bucket.bucket.arn
  sensitive = false
}

output "s3_name" {
  value = aws_s3_bucket.bucket.bucket
  sensitive = false
}
