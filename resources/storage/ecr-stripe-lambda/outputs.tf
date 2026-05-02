output "ecr_lambda_repo_arn" {
  value       = aws_ecr_repository.stripe_lambda.arn
  description = "the ARN of the stripe lambda ECR repository"
  sensitive   = true
}

output "ecr_lambda_repo_url" {
  value       = aws_ecr_repository.stripe_lambda.repository_url
  description = "the URL of the stripe lambda ECR repository"
  sensitive   = false
}
