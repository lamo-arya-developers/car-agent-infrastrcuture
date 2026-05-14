environment       = "dev"
domain_name       = "dev.xn--bilkpshjlpen-ncb1w.se"
use_custom_domain = false # flip to true once domain is validated and NS delegation is done

# GitHub identity for the application repo — used by iam-cicd-frontend to scope the OIDC trust policy.
github_org  = "lamo-arya-developers"
github_repo = "car-agent-application"

# Dev access allowlist — only these emails can sign up or log in (including via Google OAuth)
allowed_emails = [
  "aryapoureisa@gmail.com", # Arya Eisa
  "lamochi02@gmail.com",    # Lamo Kouravand
]
