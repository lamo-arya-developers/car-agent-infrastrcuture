
# Packages the allowlist check as a zip from inline Python — no ECR needed for this tiny function
# this lambda is used ONLY in dev environment and its to validate Arya and Lamo only in dev. Meaning this lambda will only be deployed in dev (not to prod).
data "archive_file" "presignup" {
  type        = "zip"
  output_path = "${path.module}/presignup.zip"
  source {
    content  = <<-PYTHON
import os

ALLOWED_EMAILS = [
    e.strip().lower()
    for e in os.environ.get('ALLOWED_EMAILS', '').split(',')
    if e.strip()
]

def handler(event, context):
    email = event['request']['userAttributes'].get('email', '').lower()

    if email not in ALLOWED_EMAILS:
        raise Exception('NotAuthorizedException: this email is not permitted to access this environment')

    return event
PYTHON
    filename = "handler.py"
  }
}

resource "aws_iam_role" "presignup" {
  name = "car-agent-presignup-lambda-role-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "presignup_logs" {
  role       = aws_iam_role.presignup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "presignup" {
  function_name    = "car-agent-presignup-lambda-dev"
  role             = aws_iam_role.presignup.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.presignup.output_path
  source_code_hash = data.archive_file.presignup.output_base64sha256

  environment {
    variables = {
      ALLOWED_EMAILS = join(",", var.allowed_emails)
    }
  }
}
