
output "ecr_agentcore_repo_arn" {
  value       = aws_ecr_repository.agentcore_ecr.arn
  description = "the ARN of the agentcore ECR repository"
  sensitive   = true
}
output "ecr_agentcore_repo_url" {
  value       = aws_ecr_repository.agentcore_ecr.repository_url
  description = "the URL of the agentcore ECR repository"
  sensitive   = false
}