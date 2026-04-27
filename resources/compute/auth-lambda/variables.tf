variable "env" {
  description = "the environment for the lambda function"
  type = string
  sensitive = true
}

variable "s3_name" {
  description = "used for the lambda function to know which bucket to interact with"
  type = string
  sensitive = false
}
variable "ecr_url" {
  description = "this is for lambda to know what image to pull from ecr"
  type = string
  sensitive = true
}
variable "cloudwatch_log_group_name" {
  description = "used for the lambda function to know which log group to write logs to"
  type = string
  sensitive = true
}
variable "lambda_execution_role_arn" {
  description = "this is the lambda execution role arn used to grant lambda access to mutliple resources"
  type = string
  sensitive = true
}
