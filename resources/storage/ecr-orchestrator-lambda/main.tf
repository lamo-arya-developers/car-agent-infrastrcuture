
resource "aws_ecr_repository" "orchestrator_lambda" {
  name                 = var.env == "prod" ? "orchestratorlambda-ecr" : "orchestrator-lambda-ecr-dev"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
