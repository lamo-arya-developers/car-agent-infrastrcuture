
resource "aws_ecr_repository" "agentcore_ecr" {
  name = var.env == "prod" ? "agentcore-ecr-prod" : "agentcore-ecr-dev"
  image_tag_mutability = "MUTABLE"
}
