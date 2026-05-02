
output "ecr_lambda_repo_arn" {
  value       = aws_ecr_repository.orchestrator_lambda.arn
  description = "this is the ARN of the lambdas ECR Repository where it gets its docker image from"
  sensitive   = true
}
output "ecr_lambda_repo_url" {
  value       = aws_ecr_repository.orchestrator_lambda.repository_url
  description = "this is the URL of the lambdas ECR Repository where it gets its docker image from"
  sensitive   = false
}