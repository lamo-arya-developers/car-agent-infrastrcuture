
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "ecr_agentcore_arn" {
  description = "ARN of the AgentCore ECR repository — used to scope image pull permissions"
  type        = string
  sensitive   = true
}

variable "cloudwatch_logs_group_arn" {
  description = "ARN of the CloudWatch log group — used to scope log write permissions"
  type        = string
  sensitive   = true
}
