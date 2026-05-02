resource "aws_lambda_function" "stripe" {
  description   = "handles Stripe payment processing — creates checkout sessions and records events to DynamoDB"
  function_name = var.env == "prod" ? "car-agent-stripe-lambda" : "car-agent-stripe-lambda-dev"
  role          = var.lambda_execution_role_arn
  timeout       = 100
  architectures = ["arm64"]
  package_type  = "Image"
  memory_size   = 1024

  logging_config {
    application_log_level = "DEBUG"
    log_format            = "JSON"
    log_group             = var.cloudwatch_log_group_name
    system_log_level      = "DEBUG"
  }

  image_uri = "${var.ecr_url}:latest"

  environment {
    variables = {
      LOG_GROUP_NAME        = var.cloudwatch_log_group_name
      STRIPE_TABLE_NAME     = var.dynamodb_stripe_name
      USER_TABLE_NAME       = var.dynamodb_user_name
      SES_CONTACT_LIST_NAME = var.ses_contact_list_name
    }
  }
}
