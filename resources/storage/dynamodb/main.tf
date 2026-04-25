resource "aws_dynamodb_table" "table" {
  name           = var.env == "prod" ? "car-agent-table-prod" : "car-agent-table-dev"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
  
}