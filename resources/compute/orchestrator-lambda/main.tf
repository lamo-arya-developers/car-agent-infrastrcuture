resource "aws_lambda_function" "orchestrator" {
  function_name = var.env == "prod" ? "car-agent-lambda-prod" : "car-agent-lambda-dev"
  role          = var.lambda_execution_role_arn
  timeout = 300
  handler       = "orchestrator.orchestrator_script"
  runtime       = "python3.12"
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
        DYNAMODB_TABLE_NAME = var.dynamodb_name
        S3_BUCKET_NAME     = var.s3_name

    }
  }
  
}
