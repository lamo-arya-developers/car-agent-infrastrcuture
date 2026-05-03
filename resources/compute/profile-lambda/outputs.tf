output "lambda_inv_arn" {
  description = "the profile lambda invoke ARN"
  value       = aws_lambda_function.profile.invoke_arn
  sensitive   = true
}

output "lambda_function_name" {
  description = "the profile lambda function name"
  value       = aws_lambda_function.profile.function_name
  sensitive   = false
}
