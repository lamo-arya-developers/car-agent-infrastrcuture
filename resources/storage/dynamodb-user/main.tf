resource "aws_dynamodb_table" "table" {
  name           = var.env == "prod" ? "user-info-table-prod" : "user-info-table-dev"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
  
}