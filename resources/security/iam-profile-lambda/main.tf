
# Trust policy — allows Lambda service to assume this role
resource "aws_iam_role" "profile_lambda" {
  name = "car-agent-profile-lambda-${var.env}"

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

resource "aws_iam_role_policy" "profile_lambda" {
  name = "car-agent-profile-lambda-policy-${var.env}"
  role = aws_iam_role.profile_lambda.id

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
      # ECR — GetAuthorizationToken is global, cannot be scoped to a resource
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      # ECR — image pull scoped to the profile lambda repository only
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = var.ecr_profile_lambda_arn
      },
      # DynamoDB — full CRUD on the user table only
      {
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = var.dynamodb_user_arn
      },
      # S3 — read, write, and delete scoped to the users/ prefix in the profile pictures bucket
      # PutObject is also required for the Lambda to sign presigned upload URLs
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_profile_pictures_arn}/users/*"
      }
    ]
  })
}
