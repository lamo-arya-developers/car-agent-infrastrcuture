
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Dedicated S3 bucket for CloudTrail audit logs — kept separate from application data
resource "aws_s3_bucket" "cloudtrail" {
  bucket = var.env == "prod" ? "car-agent-cloudtrail-logs-prod" : "car-agent-cloudtrail-logs-dev"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning prevents log tampering — if a log object is overwritten, the original is retained
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudTrail requires this specific bucket policy to write logs
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

# CloudWatch Log Group — 1 year retention for GDPR audit accountability (Article 5(2))
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = var.env == "prod" ? "/aws/cloudtrail/car-agent-prod" : "/aws/cloudtrail/car-agent-dev"
  retention_in_days = 365
}

# IAM role allowing CloudTrail to write to the CloudWatch log group
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = var.env == "prod" ? "car-agent-cloudtrail-cw-prod" : "car-agent-cloudtrail-cw-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = var.env == "prod" ? "car-agent-cloudtrail-cw-policy-prod" : "car-agent-cloudtrail-cw-policy-dev"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

resource "aws_cloudtrail" "main" {
  name           = var.env == "prod" ? "car-agent-trail-prod" : "car-agent-trail-dev"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  # Real-time log delivery to CloudWatch for monitoring and alerting
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  include_global_service_events = true  # captures IAM and STS events across all regions
  is_multi_region_trail         = false # single region deployment (eu-north-1)
  enable_log_file_validation    = true  # tamper-evident hash chain — GDPR audit integrity

  # Management events — tracks all AWS API calls (who created, deleted, or modified resources)
  advanced_event_selector {
    name = "Management events"
    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  # DynamoDB data events — tracks every read and write to personal data tables
  # Required for GDPR accountability: who accessed which user's data and when
  advanced_event_selector {
    name = "DynamoDB personal data access audit"
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    field_selector {
      field  = "resources.type"
      equals = ["AWS::DynamoDB::Table"]
    }
    field_selector {
      field  = "resources.ARN"
      equals = var.dynamodb_table_arns
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_cloudwatch
  ]
}
