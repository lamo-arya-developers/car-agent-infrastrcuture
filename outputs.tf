output "ecr_orchestrator_lambda_url" {
  value = module.ecr_orchestrator_lambda.ecr_lambda_repo_url
  sensitive = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to orchestrator lambda"
}
output "ecr_auth_lambda_url" {
  value = module.ecr_auth_lambda.ecr_lambda_repo_url
  sensitive = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to auth lambda"
}
output "ecr_agentcore_url" {
  value = module.ecr_agentcore.ecr_agentcore_repo_url
  sensitive = false
  description = "this is leveraged in the CI/CD pipeline to deploy a placeholder image to agentcore"
}