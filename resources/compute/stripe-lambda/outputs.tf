output "lambda_inv_arn" {
  description = "the stripe lambda invoke ARN"
  value       = aws_lambda_function.stripe.invoke_arn
  sensitive   = true
}

output "lambda_function_name" {
  description = "the stripe lambda function name"
  value       = aws_lambda_function.stripe.function_name
  sensitive   = false
}
