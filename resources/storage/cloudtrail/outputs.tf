
output "cloudtrail_arn" {
  value       = aws_cloudtrail.main.arn
  description = "ARN of the CloudTrail trail"
  sensitive   = true
}

output "cloudtrail_log_group_name" {
  value       = aws_cloudwatch_log_group.cloudtrail.name
  description = "CloudWatch log group where CloudTrail delivers real-time logs"
  sensitive   = false
}
