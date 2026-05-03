resource "aws_s3_bucket" "profile_pictures" {
  bucket = var.env == "prod" ? "car-agent-profile-pictures-prod" : "car-agent-profile-pictures-dev"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "profile_pictures" {
  bucket = aws_s3_bucket.profile_pictures.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "profile_pictures" {
  bucket = aws_s3_bucket.profile_pictures.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS — required for browsers to PUT directly to S3 via presigned URLs
resource "aws_s3_bucket_cors_configuration" "profile_pictures" {
  bucket = aws_s3_bucket.profile_pictures.id

  cors_rule {
    allowed_methods = ["PUT", "GET"]
    allowed_origins = [
      "https://www.xn--bilkpshjlpen-ncb1w.se",
      "https://xn--bilkpshjlpen-ncb1w.se"
    ]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}
