
# Trust policy — allows Bedrock AgentCore service to assume this role
resource "aws_iam_role" "agentcore" {
  name = "car-agentcore-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "agentcore" {
  name = "car-agentcore-policy-${var.env}"
  role = aws_iam_role.agentcore.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch — runtime logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = var.cloudwatch_logs_group_arn
      },
      # ECR — GetAuthorizationToken is a global action, must target "*"
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      # ECR — image pull scoped to the AgentCore repository only
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.ecr_agentcore_arn
      }
    ]
  })
}
