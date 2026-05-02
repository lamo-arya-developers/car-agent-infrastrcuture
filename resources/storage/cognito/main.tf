
resource "aws_cognito_user_pool" "agent" {
  name                     = var.env == "prod" ? "car-agent-user-pool" : "car-agent-user-pool-dev"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection      = "ACTIVE"

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
    password_history_size            = 5
  }

  username_configuration {
    case_sensitive = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Din verifieringskod för Bilköpshjälpen"
    email_message        = "Din verifieringskod är {####}"
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # email schema — must include string_attribute_constraints per docs
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  # name schema — must include string_attribute_constraints per docs
  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }
}

resource "aws_cognito_user_pool_domain" "agent" {
  domain       = var.env == "prod" ? "bilkopshjalpen" : "bilkopshjalpen-dev"
  user_pool_id = aws_cognito_user_pool.agent.id
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.agent.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "openid email profile"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
    name     = "name"
    picture  = "picture"
  }
}

#resource "aws_cognito_identity_provider" "facebook" {
#  user_pool_id  = aws_cognito_user_pool.agent.id
#  provider_name = "Facebook"
#  provider_type = "Facebook"
#
#  provider_details = {
#    client_id        = var.facebook_app_id
#    client_secret    = var.facebook_app_secret
#    authorize_scopes = "email,public_profile"
#    api_version      = "v17.0"
#  }
#
#  attribute_mapping = {
#    email    = "email"
#    username = "id"
#    name     = "name"
#  }
#}

resource "aws_cognito_user_pool_client" "agent" {
  name         = var.env == "prod" ? "car-agent-client" : "car-agent-client-dev"
  user_pool_id = aws_cognito_user_pool.agent.id

  generate_secret = false

  supported_identity_providers = [
    "COGNITO",
    "Google"
    #    "Facebook"
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = [
    "https://www.xn--bilkpshjlpen-ncb1w.se/auth/callback",
    "https://xn--bilkpshjlpen-ncb1w.se/auth/callback"
  ]
  logout_urls = [
    "https://www.xn--bilkpshjlpen-ncb1w.se",
    "https://xn--bilkpshjlpen-ncb1w.se"
  ]
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",     # email/password login
    "ALLOW_REFRESH_TOKEN_AUTH" # silent refresh
  ]

  depends_on = [
    aws_cognito_identity_provider.google
    #    aws_cognito_identity_provider.facebook
  ]
}