variable "env" {
  description = "the environment for the lambda function"
  type        = string
  sensitive   = true
}

variable "ecr_url" {
  description = "this is for lambda to know what image to pull from ecr"
  type        = string
  sensitive   = true
}
variable "cloudwatch_log_group_name" {
  description = "used for the lambda function to know which log group to write logs to"
  type        = string
  sensitive   = true
}
variable "lambda_execution_role_arn" {
  description = "this is the lambda execution role arn used to grant lambda access to mutliple resources"
  type        = string
  sensitive   = true
}
variable "user_table_name" {
  description = "this is the name of the table where all user records are stored and their application plan"
  type        = string
  sensitive   = true
}

variable "ses_contact_list_name" {
  description = "the SES contact list name — used to add new subscribers on first login"
  type        = string
  sensitive   = false
}
