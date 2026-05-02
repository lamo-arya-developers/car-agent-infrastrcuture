
output "lambda_inv_arn" {
  description = "the lambda functions invoke ARN"
  value       = aws_lambda_function.orchestrator.invoke_arn
  sensitive   = true
}
output "lambda_function_name" {
  description = "the lambda functions name"
  value       = aws_lambda_function.orchestrator.function_name
  sensitive   = false
}
