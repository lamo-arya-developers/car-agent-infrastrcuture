
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
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:deleteObject"
        ]
        Resource = [
          "${var.s3_arn}",
          "${var.s3_arn}/*"
        ]
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
      # SES — deletion lambda removes contacts, auth lambda creates contacts
      {
        Effect = "Allow"
        Action = [
          "ses:CreateContact",
          "ses:DeleteContact",
          "ses:GetContact"
        ]
        Resource = "*" # scope to contact list ARN once SES module is provisioned
      }
    ]
  })
}
