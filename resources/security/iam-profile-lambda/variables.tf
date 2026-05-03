variable "env" {
  description = "the environment for the profile lambda IAM role"
  type        = string
  sensitive   = true
}

variable "cloudwatch_logs_group_arn" {
  description = "the CloudWatch log group ARN for Lambda runtime logs"
  type        = string
  sensitive   = true
}

variable "ecr_profile_lambda_arn" {
  description = "the ECR repository ARN for the profile lambda image"
  type        = string
  sensitive   = true
}

variable "dynamodb_user_arn" {
  description = "the ARN of the user-info DynamoDB table"
  type        = string
  sensitive   = true
}

variable "s3_profile_pictures_arn" {
  description = "the ARN of the profile pictures S3 bucket"
  type        = string
  sensitive   = false
}
