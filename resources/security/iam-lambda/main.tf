
# Trust policy — allows Lambda service to assume this role
resource "aws_iam_role" "lambda" {
  name = "car-agent-lambda-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "car-agent-lambda-policy-${var.env}"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.cloudwatch_logs_group_arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = var.dynamodb_arns
      },
{
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = var.ecr_arns
      },
      # Cognito — deletion lambda needs to permanently remove users from the user pool
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:AdminDeleteUser"]
        Resource = "${var.cognito_user_pool_arn}"
      },
      # SES — admin access scoped to this app's domain identity and contact list only
      {
        Effect   = "Allow"
        Action   = ["ses:*"]
        Resource = var.ses_arns
      }
    ]
  })
}
