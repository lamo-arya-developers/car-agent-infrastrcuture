
output "agent_runtime_id" {
  value       = aws_bedrockagentcore_agent_runtime.agentcore.agent_runtime_id
  description = "the unique identifier of the AgentCore runtime"
  sensitive   = false
}

output "agent_runtime_arn" {
  value       = aws_bedrockagentcore_agent_runtime.agentcore.agent_runtime_arn
  description = "the ARN of the AgentCore runtime"
  sensitive   = true
}
