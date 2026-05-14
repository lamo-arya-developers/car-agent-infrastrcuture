
terraform {
  required_version = ">=1.14.0"
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Primary provider — all resources deploy to Stockholm (eu-north-1) for GDPR data residency
provider "aws" {
  region = "eu-north-1"
}

# ACM certificates for CloudFront MUST be in us-east-1 — AWS hard requirement
# Only the acm module uses this alias via providers = { aws = aws.us_east_1 }
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

#### STORAGE RESOURCES ####
module "s3" {
  source = "./resources/storage/s3"
  env    = var.environment
}
module "s3_profile_pictures" {
  source = "./resources/storage/s3-profile-pictures"
  env    = var.environment
}

module "dynamodb_car" {
  source = "./resources/storage/dynamodb-car"
  env    = var.environment
}
module "dynamodb_user" {
  source = "./resources/storage/dynamodb-user"
  env    = var.environment
}
module "dynamodb_stripe" {
  source = "./resources/storage/dynamodb-stripe"
  env    = var.environment
}
module "ecr_stripe_lambda" {
  source = "./resources/storage/ecr-stripe-lambda"
  env    = var.environment
}
module "ecr_profile_lambda" {
  source = "./resources/storage/ecr-profile-lambda"
  env    = var.environment
}
module "cloudwatch" {
  source = "./resources/storage/cloudwatch"
  env    = var.environment
}
module "ecr_orchestrator_lambda" {
  source = "./resources/storage/ecr-orchestrator-lambda"
  env    = var.environment
}
module "ecr_auth_lambda" {
  source = "./resources/storage/ecr-auth-lambda"
  env    = var.environment
}
module "ecr_deletion_lambda" {
  source = "./resources/storage/ecr-deletion-lambda"
  env    = var.environment
}
module "ecr_agentcore" {
  source = "./resources/storage/ecr-agentcore"
  env    = var.environment
}
module "cloudtrail" {
  source = "./resources/storage/cloudtrail"
  env    = var.environment
  dynamodb_table_arns = [
    module.dynamodb_car.table_arn,
    module.dynamodb_user.table_arn,
    module.dynamodb_stripe.table_arn
  ]
}
# Pre-sign-up Lambda — dev only (count = 0 in prod so it never runs there)
module "presignup_lambda" {
  count  = var.environment == "prod" ? 0 : 1
  source = "./resources/compute/presignup-lambda"

  allowed_emails = var.allowed_emails
}

module "cognito" {
  source = "./resources/storage/cognito"

  env                   = var.environment
  domain_name           = var.domain_name
  pre_signup_lambda_arn = var.environment == "prod" ? null : module.presignup_lambda[0].lambda_arn
  google_client_id      = var.google_client_id
  google_client_secret  = var.google_client_secret
  #facebook_app_id = var.facebook_app_id         --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
  #facebook_app_secret = var.facebook_app_secret --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
}
module "ses" {
  source      = "./resources/storage/ses"
  env         = var.environment
  domain_name = var.domain_name
  zone_id     = module.route53.zone_id
}

#### SECURITY RESOURCES ####
module "iam_lambda" {
  source = "./resources/security/iam-lambda"
  env    = var.environment
  ecr_arns = [
    module.ecr_orchestrator_lambda.ecr_lambda_repo_arn,
    module.ecr_auth_lambda.ecr_lambda_repo_arn,
    module.ecr_deletion_lambda.ecr_lambda_repo_arn,
    module.ecr_stripe_lambda.ecr_lambda_repo_arn
  ]
  dynamodb_arns = [
    module.dynamodb_car.table_arn,
    module.dynamodb_user.table_arn,
    module.dynamodb_stripe.table_arn
  ]
  cloudwatch_logs_group_arn = module.cloudwatch.cloudwatch_log_group_arn
  cognito_user_pool_arn     = module.cognito.cognito_user_pool_arn
  ses_arns = [
    module.ses.domain_identity_arn,
    module.ses.contact_list_arn
  ]
}
module "iam_agentcore" {
  source                    = "./resources/security/iam-agentcore"
  env                       = var.environment
  ecr_agentcore_arn         = module.ecr_agentcore.ecr_agentcore_repo_arn
  cloudwatch_logs_group_arn = module.cloudwatch.cloudwatch_log_group_arn
}
module "iam_profile_lambda" {
  source                    = "./resources/security/iam-profile-lambda"
  env                       = var.environment
  cloudwatch_logs_group_arn = module.cloudwatch.cloudwatch_log_group_arn
  ecr_profile_lambda_arn    = module.ecr_profile_lambda.ecr_lambda_repo_arn
  dynamodb_user_arn         = module.dynamodb_user.table_arn
  s3_profile_pictures_arn   = module.s3_profile_pictures.s3_arn
}
# OIDC role assumed by GitHub Actions in the application repo to deploy the frontend.
# Grants only s3:sync + cloudfront:CreateInvalidation — no long-lived credentials in GitHub.
module "iam_cicd_frontend" {
  source                      = "./resources/security/iam-cicd-frontend"
  env                         = var.environment
  s3_bucket_arn               = module.s3.s3_arn
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn
  github_org                  = var.github_org
  github_repo                 = var.github_repo
  # github_ref defaults to "ref:refs/heads/main" — only the main branch can deploy
}

#### COMPUTE RESOURCES ####
module "orchestrator_lambda" {
  source = "./resources/compute/orchestrator-lambda"

  env                       = var.environment
  dynamodb_car_name         = module.dynamodb_car.table_name
  dynamodb_user_name        = module.dynamodb_user.table_name
  ecr_url                   = module.ecr_orchestrator_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.lambda_role_arn
}
module "auth_lambda" {
  source = "./resources/compute/auth-lambda"

  env                       = var.environment
  ecr_url                   = module.ecr_auth_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.lambda_role_arn
  user_table_name           = module.dynamodb_user.table_name
  ses_contact_list_name     = module.ses.contact_list_name
}

module "deletion_lambda" {
  source = "./resources/compute/deletion-lambda"

  env                       = var.environment
  ecr_url                   = module.ecr_deletion_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.lambda_role_arn
  dynamodb_user_name        = module.dynamodb_user.table_name
  cognito_user_pool_id      = module.cognito.cognito_user_pool_id
  ses_contact_list_name     = module.ses.contact_list_name
}

module "stripe_lambda" {
  source = "./resources/compute/stripe-lambda"

  env                       = var.environment
  ecr_url                   = module.ecr_stripe_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.lambda_role_arn
  dynamodb_stripe_name      = module.dynamodb_stripe.table_name
  dynamodb_user_name        = module.dynamodb_user.table_name
  ses_contact_list_name     = module.ses.contact_list_name
}

module "profile_lambda" {
  source = "./resources/compute/profile-lambda"

  env                       = var.environment
  ecr_url                   = module.ecr_profile_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_profile_lambda.profile_lambda_role_arn
  dynamodb_user_name        = module.dynamodb_user.table_name
  s3_profile_pictures_name  = module.s3_profile_pictures.s3_name
}

module "agentcore" {
  source = "./resources/compute/agentcore"

  env      = var.environment
  ecr_url  = module.ecr_agentcore.ecr_agentcore_repo_url
  role_arn = module.iam_agentcore.agentcore_role_arn
}

#### NETWORKING RESOURCES ####
module "api_gateway" {
  source = "./resources/network/api-gateway"

  env                               = var.environment
  domain_name                       = var.domain_name
  auth_lambda_invoke_arn            = module.auth_lambda.lambda_inv_arn
  orchestrator_lambda_invoke_arn    = module.orchestrator_lambda.lambda_inv_arn
  deletion_lambda_invoke_arn        = module.deletion_lambda.lambda_inv_arn
  auth_lambda_function_name         = module.auth_lambda.lambda_function_name
  orchestrator_lambda_function_name = module.orchestrator_lambda.lambda_function_name
  deletion_lambda_function_name     = module.deletion_lambda.lambda_function_name
  cognito_user_pool_id              = module.cognito.cognito_user_pool_id
  cognito_user_pool_client_id       = module.cognito.cognito_user_pool_client_id
  cloudwatch_log_group_arn          = module.cloudwatch.cloudwatch_log_group_arn
  stripe_lambda_invoke_arn          = module.stripe_lambda.lambda_inv_arn
  stripe_lambda_function_name       = module.stripe_lambda.lambda_function_name
  profile_lambda_invoke_arn         = module.profile_lambda.lambda_inv_arn
  profile_lambda_function_name      = module.profile_lambda.lambda_function_name
}
module "route53" {
  source      = "./resources/network/route53"
  env         = var.environment
  domain_name = var.domain_name
}
# Skipped while use_custom_domain = false — ACM validation would block apply forever
# if the registrar's NS records don't point at Route53 yet.
module "acm" {
  count       = var.use_custom_domain ? 1 : 0
  source      = "./resources/network/acm"
  env         = var.environment
  domain_name = var.domain_name
  zone_id     = module.route53.zone_id

  # ACM certs for CloudFront must live in us-east-1 regardless of the main provider region
  providers = {
    aws = aws.us_east_1
  }
}
module "cloudfront" {
  source = "./resources/network/cloudfront"

  env               = var.environment
  use_custom_domain = var.use_custom_domain
  # The custom-domain inputs below are only consumed by the cloudfront module
  # when use_custom_domain = true; otherwise they're ignored.
  domain_name                    = var.use_custom_domain ? var.domain_name : null
  zone_id                        = var.use_custom_domain ? module.route53.zone_id : null
  certificate_arn                = var.use_custom_domain ? module.acm[0].certificate_arn : null
  api_gateway_endpoint           = module.api_gateway.api_gateway_endpoint
  s3_bucket_name                 = module.s3.s3_name
  s3_bucket_arn                  = module.s3.s3_arn
  s3_bucket_regional_domain_name = module.s3.s3_regional_domain_name
}