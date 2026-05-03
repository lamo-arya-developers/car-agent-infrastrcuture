variable "env" {
  description = "the environment for the profile lambda"
  type        = string
  sensitive   = true
}

variable "ecr_url" {
  description = "ECR repository URL for the profile lambda docker image"
  type        = string
  sensitive   = true
}

variable "cloudwatch_log_group_name" {
  description = "the log group the lambda writes logs to"
  type        = string
  sensitive   = true
}

variable "lambda_execution_role_arn" {
  description = "the profile lambda execution role ARN"
  type        = string
  sensitive   = true
}

variable "dynamodb_user_name" {
  description = "the name of the user-info DynamoDB table"
  type        = string
  sensitive   = true
}

variable "s3_profile_pictures_name" {
  description = "the name of the profile pictures S3 bucket — used to generate presigned upload URLs"
  type        = string
  sensitive   = false
}
