
resource "aws_ecr_repository" "stripe_lambda" {
  name                 = var.env == "prod" ? "stripe-lambda-ecr" : "stripe-lambda-ecr-dev"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
