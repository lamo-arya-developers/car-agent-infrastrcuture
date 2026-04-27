resource "aws_lambda_function" "auth" {
  description = "this lambda function is responsible for authenticating, logging out and refreshing tokens"
  function_name = var.env == "prod" ? "car-agent-auth-lambda" : "car-agent-auth-lambda-dev"
  role          = var.lambda_execution_role_arn
  timeout = 100
  # maye increase this later depending on 
  # how long we want the agent to be able to run for
  package_type = "Image"
  memory_size = 1024

  logging_config {
    application_log_level = "DEBUG"
    log_format = "JSON"
    log_group = var.cloudwatch_log_group_name
    system_log_level = "DEBUG"
  }
  image_uri    = "${var.ecr_url}:latest"

  environment {
    variables = {
        S3_BUCKET_NAME     = var.s3_name
        LOG_GROUP_NAME     = var.cloudwatch_log_group_name
    }
  } 
}
