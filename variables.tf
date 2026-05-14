variable "environment" {
  description = "this is the environment the of the infrastrcuture"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "the domain for this environment — apex for prod (xn--bilkpshjlpen-ncb1w.se), subdomain for dev (dev.xn--bilkpshjlpen-ncb1w.se)"
  type        = string
  sensitive   = false
}

variable "allowed_emails" {
  description = "emails permitted to sign up — only enforced in dev via the pre-sign-up Lambda trigger, ignored in prod"
  type        = list(string)
  default     = []
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

# Bootstrap flag — keep false until your registrar's NS records point at Route53 AND
# the ACM certificate has been issued. While false:
#   * the ACM module is skipped entirely (no validation timeout)
#   * CloudFront serves on *.cloudfront.net with its built-in cert and accepts plain HTTP
#   * no Route53 A record is created for the apex domain
# Flip to true (and re-apply) once the cert is "Issued" in ACM.
variable "use_custom_domain" {
  description = "set to true once the ACM cert for the custom domain is validated/issued; false during early bootstrap"
  type        = bool
  default     = false
}

# GitHub identity for the application repo — used by the iam-cicd-frontend module
# to scope the OIDC trust policy to the correct repo.
variable "github_org" {
  default     = "lamo-arya-developers"
  description = "GitHub organisation or username that owns the application repo (e.g. 'my-org')"
  type        = string
  sensitive   = false
}

variable "github_repo" {
  default     = "car-agent-application"
  description = "name of the application GitHub repository whose Actions will assume the frontend deploy role (e.g. 'car-agent-frontend')"
  type        = string
  sensitive   = false
}

#variable "facebook_app_id" {
#  description = "this is the Facebook app ID"
#  type      = string
#  sensitive = true
#}
#variable "facebook_app_secret" {
#  description = "this is the Facebook app secret"
#  type      = string
#  sensitive = true
#}
