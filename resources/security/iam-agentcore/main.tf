
# Trust policy — allows Bedrock AgentCore service to assume this role
resource "aws_iam_role" "agentcore" {
  name = "car-agentcore-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
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
        Resource = "${var.cloudwatch_logs_group_arn}"
      },
      # ECR — all three actions must target "*".
      # GetAuthorizationToken is inherently a global action (no resource-level support).
      # BatchGetImage and GetDownloadUrlForLayer are technically resource-scoped, but the
      # Bedrock AgentCore control-plane validator checks all three permissions against the
      # ECR URI it's given — it fails if any statement uses a narrower resource. Targeting
      # "*" is the pattern shown in AWS Bedrock AgentCore documentation and is safe here
      # because the role's trust policy already restricts who can assume it.
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}
