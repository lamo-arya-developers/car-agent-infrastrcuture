output "cloudwatch_log_group_name" {
  value       = aws_cloudwatch_log_group.agent_cw.name
  description = "the name of the cloudwatch log group that the lambda function will write logs to"
}
output "cloudwatch_log_group_arn" {
  value       = aws_cloudwatch_log_group.agent_cw.arn
  description = "the ARN of the cloudwatch log group that the lambda function will write logs to"
}