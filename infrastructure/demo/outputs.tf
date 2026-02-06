# =============================================================================
# Outputs - Single Root Module
# =============================================================================

# -----------------------------------------------------------------------------
# Core
# -----------------------------------------------------------------------------
output "suffix" {
  description = "Random suffix used for resource naming"
  value       = local.suffix
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "EKS cluster name"
  value       = var.create_eks ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.create_eks ? module.eks[0].cluster_endpoint : null
}

output "cluster_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = var.create_eks ? module.eks[0].oidc_provider_arn : null
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = var.create_eks ? "aws eks update-kubeconfig --name ${module.eks[0].cluster_name} --region ${var.aws_region}" : null
}

# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

# -----------------------------------------------------------------------------
# Wiz
# -----------------------------------------------------------------------------
output "wiz_connector_role_arn" {
  description = "IAM role ARN for Wiz connector"
  value       = var.create_wiz_connector && var.wiz_trusted_arn != "" ? module.wiz_aws_permissions[0].role_arn : null
}

# -----------------------------------------------------------------------------
# Wiz Defend Logging
# -----------------------------------------------------------------------------
output "cloudtrail_bucket_name" {
  description = "CloudTrail logs S3 bucket name"
  value       = var.enabled_logs.cloudtrail && var.create_wiz_connector ? aws_s3_bucket.cloudtrail_logs[0].id : null
}

output "cloudtrail_sqs_queue_url" {
  description = "CloudTrail SQS queue URL for Wiz integration"
  value       = var.enabled_logs.cloudtrail && var.create_wiz_connector ? module.aws_cloud_events[0].sqs_queue_url : null
}

output "route53_logs_bucket_name" {
  description = "Route53 DNS logs S3 bucket name"
  value       = var.enabled_logs.route53_logs && var.create_wiz_connector ? module.wiz_defend_logs[0].bucket_id : null
}

output "route53_sqs_queue_url" {
  description = "Route53 DNS logs SQS queue URL for Wiz integration"
  value       = var.enabled_logs.route53_logs && var.create_wiz_connector ? module.wiz_defend_logs[0].sqs_queue_urls["demo"] : null
}

# -----------------------------------------------------------------------------
# React2Shell Scenario
# -----------------------------------------------------------------------------
output "react2shell_namespace" {
  description = "Kubernetes namespace for React2Shell app"
  value       = var.create_react2shell && var.create_eks ? module.react2shell_app[0].namespace : null
}

output "react2shell_s3_bucket" {
  description = "S3 bucket with sensitive data"
  value       = var.create_react2shell ? aws_s3_bucket.sensitive_data[0].bucket : null
}

# -----------------------------------------------------------------------------
# Quick Start Commands
# -----------------------------------------------------------------------------
output "next_steps" {
  description = "Commands to run after deployment"
  value = var.create_eks ? join("\n", [
    "# 1. Update kubeconfig",
    "aws eks update-kubeconfig --name ${module.eks[0].cluster_name} --region ${var.aws_region}",
    "",
    "# 2. Verify pods are running",
    "kubectl get pods -A",
    "",
    "# 3. Get app URL (NLB hostname)",
    "kubectl get svc -n ${var.app_name}-${local.suffix} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'"
  ]) : null
}
