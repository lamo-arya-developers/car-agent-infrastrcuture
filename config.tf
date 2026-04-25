
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
module "ecr_lambda" {
  source = "./resources/storage/ecr_lambda"
  env = var.environment
}
#### SECURITY RESOURCES ####
module "iam_lambda" {
  source = "./resources/security/iam_lambda"
  env = var.environment
  ecr_arn = module.ecr_lambda.ecr_lambda_repo_arn
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
  ecr_url = module.ecr_lambda.ecr_lambda_repo_url
  cloudwatch_log_group_name = module.cloudwatch.cloudwatch_log_group_name
  lambda_execution_role_arn = module.iam_lambda.orchestrator_role_arn
}

#### NETWORKING RESOURCES ####
