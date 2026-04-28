resource "aws_dynamodb_table" "table" {
  name           = var.env == "prod" ? "car-info-table-prod" : "car-info-table-dev"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "car_id"

  attribute {
    name = "car_id"
    type = "S"
  }
}