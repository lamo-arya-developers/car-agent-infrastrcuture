variable "env" {
  description = "the environment for the lambda function"
  type        = string
  sensitive   = true
}

variable "ecr_url" {
  description = "ECR repository URL for the stripe lambda docker image"
  type        = string
  sensitive   = true
}

variable "cloudwatch_log_group_name" {
  description = "the log group the lambda writes logs to"
  type        = string
  sensitive   = true
}

variable "lambda_execution_role_arn" {
  description = "the shared lambda execution role ARN"
  type        = string
  sensitive   = true
}

variable "dynamodb_stripe_name" {
  description = "the name of the stripe-events DynamoDB table"
  type        = string
  sensitive   = true
}

variable "dynamodb_user_name" {
  description = "the name of the users DynamoDB table"
  type        = string
  sensitive   = true
}

variable "ses_contact_list_name" {
  description = "the SES contact list name — used to update subscriber preferences on payment events"
  type        = string
  sensitive   = false
}
