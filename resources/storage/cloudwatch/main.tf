resource "aws_cloudwatch_log_group" "agent_cw" {
  name              = var.env == "prod" ? "/aws/lambda/car-agent-lambda-prod" : "/aws/lambda/car-agent-lambda-dev"
  retention_in_days = 14
}