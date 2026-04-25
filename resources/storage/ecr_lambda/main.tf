
resource "aws_ecr_repository" "orchestrator_lambda" {
  name = var.env == "prod" ? "lambda-ecr-prod" : "lambda-ecr-dev"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }
}