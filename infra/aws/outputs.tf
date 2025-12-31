output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "aws_region" {
  description = "AWS Region used for deployment"
  value       = var.aws_region
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "s3_bucket_name" {
  description = "Name of the sensitive data S3 bucket"
  value       = aws_s3_bucket.sensitive_data.id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(module.eks[0].cluster_name, "")
}

output "demo_suffix" {
  description = "Suffix used to uniquely name the EKS cluster and demo app resources"
  value       = local.demo_suffix
}

output "app_namespace" {
  description = "Namespace used for the vulnerable demo app"
  value       = local.app_namespace
}

output "app_service_account_name" {
  description = "ServiceAccount name used for the vulnerable demo app"
  value       = local.app_service_account_name
}

output "app_workload_name" {
  description = "Deployment/Service base name used for the vulnerable demo app"
  value       = local.app_workload_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = try(module.eks[0].cluster_endpoint, "")
}

output "irsa_role_arn" {
  description = "ARN of the IAM Role for Service Account (IRSA)"
  value       = try(aws_iam_role.irsa_s3_role[0].arn, "")
}
