output "sns_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "SNS topic ARN for alerts"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "CloudWatch log group name"
}

output "cloudwatch_agent_role_arn" {
  value       = aws_iam_role.cloudwatch_agent.arn
  description = "CloudWatch agent IAM role ARN"
}
