output "bucket_name" {
  value       = local.cloudtrail_bucket_name
  description = "Name of the S3 bucket where CloudTrail logs are stored"
}

output "bucket_account" {
  value       = data.aws_caller_identity.current.account_id
  description = "Account ID of the AWS account where the S3 bucket is located"
}

output "sns_topic_arn" {
  value       = local.sns_topic_arn
  description = "ARN of the SNS topic used for notifications"
}

output "sns_topic_key_arn" {
  value       = local.sns_topic_key_arn
  description = "KMS Key ARN used for SNS topic encryption"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.wiz-cloud-events.arn
  description = "ARN of the SQS queue used for notifications"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.wiz-cloud-events.url
  description = "URL of the SQS queue used for notifications"
}

output "sqs_queue_key_arn" {
  value       = local.sqs_queue_key_arn
  description = "KMS Key ARN used for SQS queue encryption"
}
