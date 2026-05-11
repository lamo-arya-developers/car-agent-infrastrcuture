
output "cicd_frontend_role_arn" {
  value       = aws_iam_role.cicd_frontend.arn
  description = "ARN of the OIDC IAM role assumed by GitHub Actions in the application repo — add this as the FRONTEND_DEPLOY_ROLE_ARN secret in the app repo's GitHub Actions settings"
  sensitive   = true
}
