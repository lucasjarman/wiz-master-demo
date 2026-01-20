# Outputs for Shared AWS Infrastructure

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# -----------------------------------------------------------------------------
# EKS Outputs
# -----------------------------------------------------------------------------
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_provider" {
  description = "OIDC provider URL (without https://)"
  value       = module.eks.oidc_provider
}

# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

# -----------------------------------------------------------------------------
# Metadata Outputs
# -----------------------------------------------------------------------------
output "random_prefix_id" {
  description = "Random prefix ID for this deployment"
  value       = local.random_prefix_id
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

# NOTE: ArgoCD and Wiz K8s outputs have been moved to infrastructure/wiz/develop layer

# -----------------------------------------------------------------------------
# Wiz AWS Permissions Outputs
# -----------------------------------------------------------------------------
output "wiz_permission_object_map" {
  description = "Outputs from the Wiz AWS Permissions module (role ARN for connector)"
  value       = try(module.wiz_aws_permissions, {})
}

# -----------------------------------------------------------------------------
# Wiz Defend Logging Outputs
# -----------------------------------------------------------------------------
output "cloudtrail_name" {
  description = "Name of the CloudTrail"
  value       = try(aws_cloudtrail.demo_cloudtrail[0].name, null)
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = try(aws_cloudtrail.demo_cloudtrail[0].arn, null)
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = try(module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].id, null)
}

output "flow_logs_bucket_name" {
  description = "Name of the VPC Flow Logs S3 bucket"
  value       = try(module.aws_buckets[0].s3_buckets["flowLogs"].id, null)
}

output "route53_logs_bucket_name" {
  description = "Name of the Route53 logs S3 bucket"
  value       = try(module.wiz_defend_logs[0].bucket_id, null)
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = try(aws_flow_log.main[0].id, null)
}

output "cloudtrail_sns_topic_arn" {
  description = "ARN of the CloudTrail SNS topic"
  value       = try(aws_sns_topic.cloudtrail_sns_fanout[0].arn, null)
}

output "vpc_flow_logs_sns_topic_arn" {
  description = "ARN of the VPC Flow Logs SNS topic"
  value       = try(aws_sns_topic.vpc_flow_logs_fanout[0].arn, null)
}

output "s3_access_logs_bucket_name" {
  description = "Name of the S3 access logs bucket"
  value       = try(module.access_log_bucket[0].s3_buckets["sensitiveDataBucket"].id, null)
}

output "cloudtrail_bucket_region" {
  description = "Region of the CloudTrail bucket"
  value       = try(module.aws_buckets[0].s3_buckets["sensitiveDataBucket"].region, null)
}

output "vpc_flow_logs_bucket_region" {
  description = "Region of the VPC Flow Logs bucket"
  value       = try(module.aws_buckets[0].s3_buckets["flowLogs"].region, null)
}

output "wiz_events_object_map" {
  description = "Outputs from the Wiz AWS Cloud Events module (CloudTrail SQS queues per tenant)"
  value       = try(module.aws_cloud_events, {})
}

output "vpc_flow_logs_object_map" {
  description = "Outputs from the VPC Flow Logs module (SQS queues per tenant)"
  value       = try(module.vpc_flow_logs_queue, {})
}

output "route53_logs_bucket_region" {
  description = "Region of the Route53 logs bucket"
  value       = try(module.wiz_defend_logs[0].bucket_region, null)
}

output "route53_logs_bucket_arn" {
  description = "ARN of the Route53 logs bucket"
  value       = try(module.wiz_defend_logs[0].bucket_arn, null)
}

output "route53_logs_sns_topic_arn" {
  description = "ARN of the Route53 logs SNS topic"
  value       = try(module.wiz_defend_logs[0].sns_topic_arn, null)
}

output "route53_logs_kms_key_arn" {
  description = "ARN of the Route53 logs KMS key"
  value       = try(module.wiz_defend_logs[0].kms_key_arn, null)
}

output "route53_logs_sqs_queue_arns" {
  description = "Map of SQS queue ARNs for Route53 logs by role prefix"
  value       = try(module.wiz_defend_logs[0].sqs_queue_arns, {})
}

output "route53_logs_sqs_queue_urls" {
  description = "Map of SQS queue URLs for Route53 logs by role prefix"
  value       = try(module.wiz_defend_logs[0].sqs_queue_urls, {})
}

output "route53_logs_iam_policy_arns" {
  description = "Map of IAM policy ARNs for Route53 logs by role prefix"
  value       = try(module.wiz_defend_logs[0].iam_policy_arns, {})
}
