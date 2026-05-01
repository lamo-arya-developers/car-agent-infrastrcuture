
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "dynamodb_table_arns" {
  description = "ARNs of the DynamoDB tables containing personal data — scopes CloudTrail data events to only these tables"
  type        = list(string)
  sensitive   = true
}
