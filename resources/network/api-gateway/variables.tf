
variable "env" {
  description = "the environment for all resources"
  type = string
  sensitive = true
}

variable "auth_lambda_invoke_arn" {
  description = "this is the auth lambda's invoke ARN"
  type = string
  sensitive = true
}
variable "orchestrator_lambda_invoke_arn" {
  description = "this is the orchestrator lambda's invoke ARN"
  type = string
  sensitive = true
}
variable "cognito_user_pool_id" {
  description = "this is the userpool ID where are users are stored"
  type = string
  sensitive = true
}

variable "cognito_client_id" {
  description = "this is the client ID for the Cognito user pool"
  type = string
  sensitive = true
}

variable "orchestrator_lambda_function_name" {
  description = "this is the name of the orchestrator lambda function"
  type = string
  sensitive = false
}
variable "auth_lambda_function_name" {
  description = "this is the name of the auth lambda function"
  type = string
  sensitive = false
}

variable "cloudwatch_log_group_arn" {
  description = "this is the ARN of the CloudWatch log group"
  type = string
  sensitive = true
}
