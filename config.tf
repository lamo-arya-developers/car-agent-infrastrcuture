
terraform {
  required_version = ">=1.14.0"
  backend "s3" {
    bucket  = "bilkpshjalpen-tfstate-files"
    key     = "product/car-agent/poc/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }

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
module "cognito" {
  source = "./resources/storage/cognito"

  env                  = var.environment
  google_client_id     = var.environment == "prod" ? var.google_client_id : "${var.google_client_id}-dev"
  google_client_secret = var.environment == "prod" ? var.google_client_secret : "${var.google_client_secret}-dev"
  #facebook_app_id = var.facebook_app_id         --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
  #facebook_app_secret = var.facebook_app_secret --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
}
module "ses" {
  source      = "./resources/storage/ses"
  env         = var.environment
  domain_name = "xn--bilkpshjlpen-ncb1w.se"
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
  auth_lambda_invoke_arn            = module.auth_lambda.lambda_inv_arn
  orchestrator_lambda_invoke_arn    = module.orchestrator_lambda.lambda_inv_arn
  deletion_lambda_invoke_arn        = module.deletion_lambda.lambda_inv_arn
  auth_lambda_function_name         = module.auth_lambda.lambda_function_name
  orchestrator_lambda_function_name = module.orchestrator_lambda.lambda_function_name
  deletion_lambda_function_name     = module.deletion_lambda.lambda_function_name
  cognito_user_pool_id              = var.environment == "prod" ? module.cognito.cognito_user_pool_id : "${module.cognito.cognito_user_pool_id}-dev"
  cognito_user_pool_client_id       = var.environment == "prod" ? module.cognito.cognito_user_pool_client_id : "${module.cognito.cognito_user_pool_client_id}-dev"
  cloudwatch_log_group_arn          = module.cloudwatch.cloudwatch_log_group_arn
  stripe_lambda_invoke_arn          = module.stripe_lambda.lambda_inv_arn
  stripe_lambda_function_name       = module.stripe_lambda.lambda_function_name
  profile_lambda_invoke_arn         = module.profile_lambda.lambda_inv_arn
  profile_lambda_function_name      = module.profile_lambda.lambda_function_name
}
module "route53" {
  source      = "./resources/network/route53"
  env         = var.environment
  domain_name = "xn--bilkpshjlpen-ncb1w.se"
}
module "acm" {
  source      = "./resources/network/acm"
  env         = var.environment
  domain_name = "xn--bilkpshjlpen-ncb1w.se"
  zone_id     = module.route53.zone_id

  # ACM certs for CloudFront must live in us-east-1 regardless of the main provider region
  providers = {
    aws = aws.us_east_1
  }
}
module "cloudfront" {
  source = "./resources/network/cloudfront"

  env                            = var.environment
  domain_name                    = "xn--bilkpshjlpen-ncb1w.se"
  zone_id                        = module.route53.zone_id
  certificate_arn                = module.acm.certificate_arn
  api_gateway_endpoint           = module.api_gateway.api_gateway_endpoint
  s3_bucket_name                 = module.s3.s3_name
  s3_bucket_arn                  = module.s3.s3_arn
  s3_bucket_regional_domain_name = module.s3.s3_regional_domain_name
}