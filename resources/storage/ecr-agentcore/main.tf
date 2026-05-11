
resource "aws_ecr_repository" "agentcore_ecr" {
  name                 = var.env == "prod" ? "agentcore-ecr" : "agentcore-ecr-dev"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
