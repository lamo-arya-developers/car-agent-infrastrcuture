
resource "aws_ecr_repository" "deletion_lambda" {
  name                 = var.env == "prod" ? "deletion-lambda-ecr" : "deletion-lambda-ecr-dev"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
