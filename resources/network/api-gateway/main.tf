
# Resolves the current region dynamically so the Cognito JWT issuer URL
# stays correct regardless of which region the provider is pointed at
data "aws_region" "current" {}

resource "aws_apigatewayv2_api" "agent" {
  name          = var.env == "prod" ? "car-agent-api" : "car-agent-api-dev"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "https://www.xn--bilkpshjlpen-ncb1w.se",
      "https://xn--bilkpshjlpen-ncb1w.se",
    ]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
    allow_credentials = true
    expose_headers = [ "Set-Cookie" ]
    max_age = 300
  }
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.agent.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = var.env == "prod" ? "car-agent-jwt-authorizer" : "car-agent-jwt-authorizer-dev"

  jwt_configuration {
    audience = [var.cognito_user_pool_client_id]
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

#### Login, Refresh & Logout Lambda ####
resource "aws_apigatewayv2_integration" "auth_lambda" {
  api_id                 = aws_apigatewayv2_api.agent.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.auth_lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_callback" {
  api_id             = aws_apigatewayv2_api.agent.id
  route_key          = "POST /auth/callback"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_refresh" {
  api_id             = aws_apigatewayv2_api.agent.id
  route_key          = "POST /auth/refresh"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "auth_logout" {
  api_id             = aws_apigatewayv2_api.agent.id
  route_key          = "POST /auth/logout"
  target             = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
  authorization_type = "NONE"
}

#### Orchestration Lambda ####
resource "aws_apigatewayv2_integration" "orchestrator_lambda" {
  api_id                 = aws_apigatewayv2_api.agent.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.orchestrator_lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "agent" {
  api_id             = aws_apigatewayv2_api.agent.id
  route_key          = "POST /invoke"
  target             = "integrations/${aws_apigatewayv2_integration.orchestrator_lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.agent.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit = 50
    detailed_metrics_enabled = false # when paying customers come -> true
  }

  access_log_settings {
    destination_arn = var.cloudwatch_log_group_arn
    format          = jsonencode({
      requestId         = "$context.requestId"
      sourceIp          = "$context.identity.sourceIp"
      requestTime       = "$context.requestTime"
      httpMethod        = "$context.httpMethod"
      routeKey          = "$context.routeKey"
      status            = "$context.status"
      protocol          = "$context.protocol"
      responseLength    = "$context.responseLength"
      integrationStatus = "$context.integrationStatus"
      errorMessage      = "$context.error.message"
      authorizerError   = "$context.authorizer.error"
      integrationError  = "$context.integration.error"
      userAgent         = "$context.identity.userAgent"
      domainName        = "$context.domainName"
    })
  }
}

resource "aws_lambda_permission" "orchestrator_lambda_api_gateway" {
  statement_id  = "AllowAPIGatewayInvokeOrchestratorLambda"
  action        = "lambda:InvokeFunction"
  function_name = var.orchestrator_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.agent.execution_arn}/*/*"
}
resource "aws_lambda_permission" "auth_lambda_api_gateway" {
  statement_id  = "AllowAPIGatewayInvokeAuthLambda"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.agent.execution_arn}/*/*"
}

