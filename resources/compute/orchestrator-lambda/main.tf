resource "aws_lambda_function" "orchestrator" {
  description   = "this lambda function is responsible for orchestrating the car agent's tasks, it will be triggered by an API Gateway and will interact with s3 and dynamodb to manage the agent's state and data"
  function_name = var.env == "prod" ? "car-agent-orchestrator-lambda" : "car-agent-orchestrator-lambda-dev"
  role          = var.lambda_execution_role_arn
  timeout       = 300
  architectures = ["arm64"]
  # maye increase this later depending on 
  # how long we want the agent to be able to run for
  package_type = "Image"
  memory_size  = 1024

  logging_config {
    application_log_level = "DEBUG"
    log_format            = "JSON"
    log_group             = var.cloudwatch_log_group_name
    system_log_level      = "DEBUG"
  }
  image_uri = "${var.ecr_url}:latest"

  environment {
    variables = {
      DYNAMODB_CAR_TABLE_NAME  = var.dynamodb_car_name
      DYNAMODB_USER_TABLE_NAME = var.dynamodb_user_name
      LOG_GROUP_NAME           = var.cloudwatch_log_group_name
    }
  }
}
