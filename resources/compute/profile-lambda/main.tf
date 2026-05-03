resource "aws_lambda_function" "profile" {
  description   = "handles user profile CRUD and generates presigned S3 URLs for profile picture uploads"
  function_name = var.env == "prod" ? "car-agent-profile-lambda" : "car-agent-profile-lambda-dev"
  role          = var.lambda_execution_role_arn
  timeout       = 30
  architectures = ["arm64"]
  package_type  = "Image"
  memory_size   = 512

  logging_config {
    application_log_level = "DEBUG"
    log_format            = "JSON"
    log_group             = var.cloudwatch_log_group_name
    system_log_level      = "DEBUG"
  }

  image_uri = "${var.ecr_url}:latest"

  environment {
    variables = {
      LOG_GROUP_NAME          = var.cloudwatch_log_group_name
      USER_TABLE_NAME         = var.dynamodb_user_name
      PROFILE_PICTURES_BUCKET = var.s3_profile_pictures_name
    }
  }
}
