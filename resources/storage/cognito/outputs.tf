
output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.agent.id
  description = "the Cognito user pool ID"
  sensitive   = true
}

output "cognito_user_pool_arn" {
  value       = aws_cognito_user_pool.agent.arn
  description = "the Cognito user pool ARN — used to scope AdminDeleteUser IAM permission"
  sensitive   = true
}

output "cognito_user_pool_client_id" {
  value       = aws_cognito_user_pool_client.agent.id
  description = "the client ID of the Cognito user pool"
  sensitive   = true
}