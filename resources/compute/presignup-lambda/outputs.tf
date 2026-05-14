
output "lambda_arn" {
  value       = aws_lambda_function.presignup.arn
  description = "ARN of the pre-sign-up Lambda — passed to the Cognito module to attach as a trigger"
  sensitive   = false
}
