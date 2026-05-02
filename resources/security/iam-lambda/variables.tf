variable "env" {
  description = "the environment for the lambda function"
  type        = string
  sensitive   = true
}

variable "ecr_arns" {
  description = "used for the lambda functions to be granted access to pull images from the ECR repository repositories"
  type        = list(string)
  sensitive   = true
}
variable "s3_arn" {
  description = "used for the lambda function to be granted access for read & write"
  type        = string
  sensitive   = true
}
variable "dynamodb_arns" {
  description = "used for the execution role to be granted access for read & write"
  type        = list(string)
  sensitive   = true
}
variable "cloudwatch_logs_group_arn" {
  description = "this is needed in the lambda execution role to access cloudwatch"
  type        = string
  sensitive   = true
}

variable "cognito_user_pool_arn" {
  description = "the Cognito user pool ARN — scopes AdminDeleteUser to this pool only"
  type        = string
  sensitive   = true
}

variable "ses_arns" {
  description = "SES resource ARNs (domain identity + contact list) — scopes ses:* to only this app's resources"
  type        = list(string)
  sensitive   = false
}