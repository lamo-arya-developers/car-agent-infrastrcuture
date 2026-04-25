output "ecr_lambda_url" {
  value = module.ecr_lambda.ecr_lambda_repo_url
  sensitive = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to lambda"
}
output "ecr_agentcore_url" {
  value = module.ecr_agentcore.ecr_agentcore_repo_url
  sensitive = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to agentcore"
}