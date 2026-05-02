output "ecr_lambda_repo_arn" {
  value       = aws_ecr_repository.deletion_lambda.arn
  description = "the ARN of the deletion lambda ECR repository where it gets its docker image from"
  sensitive   = true
}
output "ecr_lambda_repo_url" {
  value       = aws_ecr_repository.deletion_lambda.repository_url
  description = "the URL of the deletion lambda ECR repository where it gets its docker image from"
  sensitive   = false
}
