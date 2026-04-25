
resource "aws_ecr_repository" "orchestrator_lambda" {
  name = var.env == "prod" ? "lambda-ecr-prod" : "lambda-ecr-dev"
  image_tag_mutability = "MUTABLE"
}
