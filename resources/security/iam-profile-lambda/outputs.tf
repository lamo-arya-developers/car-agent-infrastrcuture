output "profile_lambda_role_arn" {
  description = "the ARN of the profile lambda execution role"
  value       = aws_iam_role.profile_lambda.arn
  sensitive   = true
}
