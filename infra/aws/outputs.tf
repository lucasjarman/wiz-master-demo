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

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = try(module.eks[0].cluster_endpoint, "")
}

# Conditional EC2 Outputs
output "ec2_public_ip" {
  description = "Public IP of Amazon Linux instance"
  value       = length(aws_eip.demo_app) > 0 ? aws_eip.demo_app[0].public_ip : ""
}

output "ec2_public_dns" {
  description = "Public DNS of Amazon Linux instance"
  value       = length(aws_eip.demo_app) > 0 ? aws_eip.demo_app[0].public_dns : ""
}

output "app_url" {
  description = "URL for Amazon Linux app (Port 3000)"
  value       = length(aws_eip.demo_app) > 0 ? "http://${aws_eip.demo_app[0].public_ip}:3000" : ""
}

output "ec2_ubuntu_public_ip" {
  description = "Public IP of Ubuntu instance"
  value       = length(aws_eip.demo_app_ubuntu) > 0 ? aws_eip.demo_app_ubuntu[0].public_ip : ""
}

output "ec2_ubuntu_public_dns" {
  description = "Public DNS of Ubuntu instance"
  value       = length(aws_eip.demo_app_ubuntu) > 0 ? aws_eip.demo_app_ubuntu[0].public_dns : ""
}

output "app_url_ubuntu" {
  description = "URL for Ubuntu app (Port 80)"
  value       = length(aws_eip.demo_app_ubuntu) > 0 ? "http://${aws_eip.demo_app_ubuntu[0].public_ip}" : ""
}
