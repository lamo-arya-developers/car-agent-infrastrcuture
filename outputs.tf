output "ecr_orchestrator_lambda_url" {
  value       = module.ecr_orchestrator_lambda.ecr_lambda_repo_url
  sensitive   = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to orchestrator lambda"
}
output "ecr_auth_lambda_url" {
  value       = module.ecr_auth_lambda.ecr_lambda_repo_url
  sensitive   = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to auth lambda"
}
output "ecr_agentcore_url" {
  value       = module.ecr_agentcore.ecr_agentcore_repo_url
  sensitive   = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to agentcore"
}
output "ecr_deletion_lambda_url" {
  value       = module.ecr_deletion_lambda.ecr_lambda_repo_url
  sensitive   = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to the deletion lambda"
}
output "ecr_stripe_lambda_url" {
  value       = module.ecr_stripe_lambda.ecr_lambda_repo_url
  sensitive   = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to the stripe lambda"
}
output "ecr_profile_lambda_url" {
  value       = module.ecr_profile_lambda.ecr_lambda_repo_url
  sensitive   = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to the profile lambda"
}
output "s3_bucket_name" {
  value       = module.s3.s3_name
  sensitive   = true
  description = "used in CI/CD to sync the Vite dist/ build to the correct S3 bucket per environment"
}
output "cloudfront_distribution_id" {
  value       = module.cloudfront.cloudfront_distribution_id
  sensitive   = true
  description = "used in CI/CD to invalidate the CloudFront cache after a frontend deploy"
}

output "cicd_frontend_role_arn" {
  value       = module.iam_cicd_frontend.cicd_frontend_role_arn
  sensitive   = true
  description = "ARN of the OIDC IAM role for the application repo CI/CD — add as FRONTEND_DEPLOY_ROLE_ARN secret in the app repo's GitHub Actions settings"
}

# Visit this in a browser to load the site while the custom domain isn't live yet.
# Works over both http:// and https:// because viewer_protocol_policy = allow-all when use_custom_domain = false.
output "cloudfront_domain_name" {
  value       = module.cloudfront.cloudfront_domain_name
  sensitive   = false
  description = "the *.cloudfront.net hostname for the distribution — used to view the site before the custom domain is wired up"
}
