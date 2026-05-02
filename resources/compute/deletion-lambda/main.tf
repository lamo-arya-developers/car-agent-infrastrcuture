resource "aws_lambda_function" "deletion" {
  description   = "handles permanent account deletion — removes user from DynamoDB, SES contact list, and Cognito"
  function_name = var.env == "prod" ? "car-agent-deletion-lambda" : "car-agent-deletion-lambda-dev"
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
      USER_TABLE_NAME       = var.dynamodb_user_name
      COGNITO_USER_POOL_ID  = var.cognito_user_pool_id
      SES_CONTACT_LIST_NAME = var.ses_contact_list_name
    }
  }
}
