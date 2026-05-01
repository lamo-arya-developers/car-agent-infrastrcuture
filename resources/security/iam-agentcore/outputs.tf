
output "agentcore_role_arn" {
  value       = aws_iam_role.agentcore.arn
  description = "the ARN of the IAM execution role assumed by the AgentCore runtime"
  sensitive   = true
}
