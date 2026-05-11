
# Look up the GitHub OIDC provider that already exists in this AWS account.
# The infra CI/CD pipeline created it — this module just references it.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Trust policy — allows GitHub Actions in the application repo to assume this role
# via OIDC (no long-lived AWS credentials stored in GitHub).
resource "aws_iam_role" "cicd_frontend" {
  name = var.env == "prod" ? "car-agent-cicd-frontend" : "car-agent-cicd-frontend-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "${data.aws_iam_openid_connect_provider.github.arn}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # "aud" must be sts.amazonaws.com when using the official GitHub OIDC action
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Scope to the application repo + allowed ref (e.g. refs/heads/main).
            # Using StringLike lets the default "*" cover all refs while still allowing
            # the caller to lock it down to a single branch.
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:${var.github_ref}"
          }
        }
      }
    ]
  })
}

# Permission policy — least-privilege: only the two operations the deploy action needs.
resource "aws_iam_role_policy" "cicd_frontend" {
  name = var.env == "prod" ? "car-agent-cicd-frontend-policy" : "car-agent-cicd-frontend-policy-dev"
  role = aws_iam_role.cicd_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 — sync dist/ into the frontend bucket (aws s3 sync --delete)
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        # ListBucket is a bucket-level action — must target the bucket ARN, not /*
        Resource = "${var.s3_bucket_arn}"
      },
      {
        Sid    = "S3ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",   # needed by aws s3 sync to diff local vs remote
          "s3:DeleteObject" # needed by --delete flag to purge stale assets
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      # CloudFront — invalidate cache after every deploy so users get the new build immediately
      {
        Sid      = "CloudFrontInvalidate"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "${var.cloudfront_distribution_arn}"
      }
    ]
  })
}
