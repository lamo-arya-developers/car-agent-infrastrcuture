
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "s3_bucket_arn" {
  description = "ARN of the frontend S3 bucket — scopes s3:PutObject, s3:GetObject, s3:DeleteObject, and s3:ListBucket to this bucket only"
  type        = string
  sensitive   = false
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution — scopes cloudfront:CreateInvalidation to this distribution only"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organisation or username that owns the application repo (e.g. 'my-org')"
  type        = string
  sensitive   = false
}

variable "github_repo" {
  description = "name of the application GitHub repository that will assume this role (e.g. 'car-agent-frontend')"
  type        = string
  sensitive   = false
}

variable "github_ref" {
  description = "GitHub ref pattern allowed to assume this role. Use 'ref:refs/heads/main' to restrict to the main branch only, or '*' to allow any ref in the repo"
  type        = string
  default     = "ref:refs/heads/main"
  sensitive   = false
}
