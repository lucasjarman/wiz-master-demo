output "sqs_queue_arn" {
  value       = aws_sqs_queue.wiz_vpc_flow_logs_queue.arn
  description = "The ARN of the SQS queue for VPC Flow Logs"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.wiz_vpc_flow_logs_queue.id
  description = "The URL of the SQS queue for VPC Flow Logs"
}
