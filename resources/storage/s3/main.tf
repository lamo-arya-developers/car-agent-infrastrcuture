resource "aws_s3_bucket" "bucket" {
  bucket = var.env == "prod" ? "car-ai-agent-bucket-prod" : "car-ai-agent-bucket-dev"
  # S3 bucket for car AI agent's frontend application files.
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # AWS-managed key — no cost, audit trail via CloudTrail
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

