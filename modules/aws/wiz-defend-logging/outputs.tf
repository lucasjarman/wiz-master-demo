# S3 Bucket Outputs
output "bucket_id" {
  description = "ID of the Route53 logs S3 bucket"
  value       = local.create_s3_bucket ? aws_s3_bucket.route53_logs[0].id : null
  depends_on  = [aws_s3_bucket_policy.route53_logs]
}

output "bucket_arn" {
  description = "ARN of the Route53 logs S3 bucket"
  value       = local.bucket_arn
  depends_on  = [aws_s3_bucket_policy.route53_logs]
}

output "bucket_region" {
  description = "Region of the Route53 logs S3 bucket"
  value       = local.create_s3_bucket ? aws_s3_bucket.route53_logs[0].region : null
}

# SNS Topic Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for Route53 logs notifications"
  value       = local.sns_topic_arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for Route53 logs notifications"
  value       = local.create_sns_topic ? aws_sns_topic.route53_logs_fanout[0].name : null
}

# SQS Queue Outputs (map of queues by role prefix)
output "sqs_queue_arns" {
  description = "Map of SQS queue ARNs for Route53 logs by role prefix"
  value       = { for k, v in aws_sqs_queue.wiz_route53_logs_queue : k => v.arn }
}

output "sqs_queue_urls" {
  description = "Map of SQS queue URLs for Route53 logs by role prefix"
  value       = { for k, v in aws_sqs_queue.wiz_route53_logs_queue : k => v.url }
}

output "sqs_queue_names" {
  description = "Map of SQS queue names for Route53 logs by role prefix"
  value       = { for k, v in aws_sqs_queue.wiz_route53_logs_queue : k => v.name }
}

# IAM Policy Outputs (map of policies by role prefix)
output "iam_policy_arns" {
  description = "Map of IAM policy ARNs for Wiz access to Route53 logs by role prefix"
  value       = { for k, v in aws_iam_policy.wiz_allow_route53_logs_bucket_access : k => v.arn }
}

output "iam_policy_names" {
  description = "Map of IAM policy names for Wiz access to Route53 logs by role prefix"
  value       = { for k, v in aws_iam_policy.wiz_allow_route53_logs_bucket_access : k => v.name }
}

# KMS Key Outputs
output "kms_key_arn" {
  description = "ARN of the KMS key for Route53 logs (if created)"
  value       = local.kms_key_arn
}

output "kms_key_id" {
  description = "ID of the KMS key for Route53 logs (if created)"
  value       = local.create_kms_key ? aws_kms_key.wiz_route53_logs[0].key_id : null
}

# Route53 Resolver Query Log Outputs
output "resolver_query_log_config_id" {
  description = "ID of the Route53 Resolver query log configuration"
  value       = length(var.vpc_ids) > 0 ? aws_route53_resolver_query_log_config.this[0].id : null
}

output "resolver_query_log_config_arn" {
  description = "ARN of the Route53 Resolver query log configuration"
  value       = length(var.vpc_ids) > 0 ? aws_route53_resolver_query_log_config.this[0].arn : null
}

output "resolver_query_log_association_ids" {
  description = "Map of VPC IDs to their Route53 Resolver query log association IDs"
  value       = { for k, v in aws_route53_resolver_query_log_config_association.this : k => v.id }
}
