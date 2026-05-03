output "ecr_lambda_repo_arn" {
  description = "the ARN of the profile lambda ECR repository"
  value       = aws_ecr_repository.profile_lambda.arn
  sensitive   = true
}

output "ecr_lambda_repo_url" {
  description = "the URL of the profile lambda ECR repository"
  value       = aws_ecr_repository.profile_lambda.repository_url
  sensitive   = false
}
