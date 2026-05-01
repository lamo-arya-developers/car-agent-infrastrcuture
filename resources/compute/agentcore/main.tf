
resource "aws_bedrockagentcore_agent_runtime" "agentcore" {
  agent_runtime_name = var.env == "prod" ? "car-agent-runtime-prod" : "car-agent-runtime-dev"
  description        = "AgentCore runtime for the car agent — containerised execution environment hosted on ECR"
  role_arn           = var.role_arn

  agent_runtime_artifact {
    container_configuration {
      container_uri = "${var.ecr_url}:latest"
    }
  }

  network_configuration {
    network_mode = "PUBLIC"
  }
}

resource "aws_bedrockagentcore_agent_runtime_endpoint" "agentcore" {
  name             = var.env == "prod" ? "car-agent-endpoint-prod" : "car-agent-endpoint-dev"
  agent_runtime_id = aws_bedrockagentcore_agent_runtime.agentcore.agent_runtime_id
  description      = "Network endpoint for the car agent AgentCore runtime"
}
