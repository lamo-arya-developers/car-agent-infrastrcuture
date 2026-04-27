
terraform {
  required_version = ">=1.14.0"
  backend "s3" {
    bucket  = "remote-tfstates-bucket"
    key     = "product/car-agent/poc/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

#### STORAGE RESOURCES ####
module "s3" {
  source = "./resources/storage/s3"
  env = var.environment
}
module "dynamodb" {
  source = "./resources/storage/dynamodb"
  env = var.environment
}
module "cloudwatch" {
  source = "./resources/storage/cloudwatch"
  env = var.environment
}
module "ecr_orchestrator_lambda" {
  source = "./resources/storage/ecr-orchestrator-lambda"
  env = var.environment
}
module "ecr_auth_lambda" {
  source = "./resources/storage/ecr-auth-lambda"
  env = var.environment
}
module "ecr_agentcore" {
  source = "./resources/storage/ecr-agentcore"
  env = var.environment
}
module "cognito" {
  source = "./resources/storage/cognito"
  
  env = var.environment
  google_client_id = var.environment == "prod" ? var.google_client_id : "${var.google_client_id}-dev"
  google_client_secret = var.environment == "prod" ? var.google_client_secret : "${var.google_client_secret}-dev"
  #facebook_app_id = var.facebook_app_id         --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
  #facebook_app_secret = var.facebook_app_secret --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
}

#### SECURITY RESOURCES ####
module "iam_lambda" {
  source = "./resources/security/iam-lambda"
  env = var.environment
  ecr_arns = [
    module.ecr_orchestrator_lambda.ecr_lambda_repo_arn,
    module.ecr_auth_lambda.ecr_lambda_repo_arn
  ]
  s3_arn = module.s3.s3_arn
  dynamodb_arn = module.dynamodb.table_arn
  cloudwatch_logs_group_arn = module.cloudwatch.cloudwatch_log_group_arn
}

#### COMPUTE RESOURCES ####
module "orchestrator_lambda" {
  source = "./resources/compute/orchestrator-lambda"

  env = var.environment
  s3_name = module.s3.s3_name
  dynamodb_name = module.dynamodb.table_name
  ecr_url = module.ecr_orchestrator_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.lambda_role_arn
}
module "auth_lambda" {
  source = "./resources/compute/auth-lambda"

  env = var.environment
  ecr_url = module.ecr_auth_lambda.ecr_lambda_repo_url
  s3_name = module.s3.s3_name
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.lambda_role_arn
}

#### NETWORKING RESOURCES ####
module "api_gateway" {
  source = "./resources/network/api-gateway"

  env = var.environment
  auth_lambda_invoke_arn = module.auth_lambda.lambda_inv_arn
  orchestrator_lambda_invoke_arn = module.orchestrator_lambda.lambda_inv_arn
  auth_lambda_function_name = module.auth_lambda.lambda_function_name
  orchestrator_lambda_function_name = module.orchestrator_lambda.lambda_function_name
  cognito_user_pool_id = var.environment == "prod" ? module.cognito.user_pool_id : "${module.cognito.user_pool_id}-dev"
  cognito_client_id = var.environment == "prod" ? module.cognito.user_pool_client_id : "${module.cognito.user_pool_client_id}-dev"
  cloudwatch_log_group_arn = module.cloudwatch.cloudwatch_log_group_arn
}