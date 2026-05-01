
output "api_gateway_endpoint" {
  value       = aws_apigatewayv2_api.agent.api_endpoint
  description = "the base URL of the API Gateway — used as the CloudFront API origin domain"
  sensitive   = false
}
