
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "the domain for this environment — used for Cognito callback and logout URLs"
  type        = string
  sensitive   = false
}

variable "pre_signup_lambda_arn" {
  description = "ARN of the pre-sign-up Lambda trigger — null in prod (open registration), set in dev to enforce the email allowlist"
  type        = string
  default     = null
  sensitive   = false
}

variable "google_client_id" {
  description = "this is the Google client ID"
  type        = string
  sensitive   = true
}
variable "google_client_secret" {
  description = "this is the Google client secret"
  type        = string
  sensitive   = true
}

#variable "facebook_app_id" {     --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
#  description = "this is the Facebook app ID"
#  type      = string
#  sensitive = true
#}
#variable "facebook_app_secret" { --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
#  description = "this is the Facebook app secret"
#  type      = string
#  sensitive = true
#}
