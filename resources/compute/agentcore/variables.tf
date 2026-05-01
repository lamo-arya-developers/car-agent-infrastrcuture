
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "ecr_url" {
  description = "the URL of the AgentCore ECR repository used as the container image source"
  type        = string
  sensitive   = false
}

variable "role_arn" {
  description = "the ARN of the IAM execution role assumed by the AgentCore runtime"
  type        = string
  sensitive   = true
}
