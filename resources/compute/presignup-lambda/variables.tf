
variable "allowed_emails" {
  description = "list of email addresses permitted to sign up — enforced via Cognito pre-sign-up trigger"
  type        = list(string)
}
