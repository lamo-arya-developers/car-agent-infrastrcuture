
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.agent.id
  description = "this is the cognito user pool ID"
  sensitive = true
}
output "client_id" {
  value = aws_cognito_user_pool_client.agent.id
  description = "this is the client ID of Cognito"
  sensitive = true
}