output "lambda_inv_arn" {
  description = "the deletion lambda invoke ARN"
  value       = aws_lambda_function.deletion.invoke_arn
  sensitive   = true
}

output "lambda_function_name" {
  description = "the deletion lambda function name"
  value       = aws_lambda_function.deletion.function_name
  sensitive   = false
}
