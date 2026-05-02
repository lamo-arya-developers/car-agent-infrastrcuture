variable "env" {
  description = "the environment for the lambda function"
  type        = string
  sensitive   = true
}

variable "ecr_url" {
  description = "ECR repository URL for the deletion lambda docker image"
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

variable "dynamodb_user_name" {
  description = "the name of the user-info DynamoDB table"
  type        = string
  sensitive   = true
}

variable "cognito_user_pool_id" {
  description = "the Cognito user pool ID — used to call AdminDeleteUser"
  type        = string
  sensitive   = true
}

variable "ses_contact_list_name" {
  description = "the SES contact list name — used to call DeleteContact"
  type        = string
  sensitive   = false
}
