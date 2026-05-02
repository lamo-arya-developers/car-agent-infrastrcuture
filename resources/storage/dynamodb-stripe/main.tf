resource "aws_dynamodb_table" "table" {
  name         = var.env == "prod" ? "stripe-events-prod" : "stripe-events-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  server_side_encryption {
    enabled     = true
    kms_key_arn = null # null = AWS-managed key (aws/dynamodb) — audit trail via CloudTrail
  }

  point_in_time_recovery {
    enabled = true # GDPR Article 5(1)(f) — data integrity and availability
  }

  attribute {
    name = "event_id"
    type = "S"
  }
}
