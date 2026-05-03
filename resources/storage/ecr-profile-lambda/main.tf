resource "aws_ecr_repository" "profile_lambda" {
  name                 = var.env == "prod" ? "profile-lambda-ecr" : "profile-lambda-ecr-dev"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
