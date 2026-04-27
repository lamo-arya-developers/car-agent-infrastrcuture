
resource "aws_ecr_repository" "auth_lambda" {
  name = var.env == "prod" ? "auth-lambda-ecr" : "auth-lambda-ecr-dev"
  image_tag_mutability = "MUTABLE"
  force_delete = true
}
