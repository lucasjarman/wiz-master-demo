output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "random_suffix" {
  description = "Random suffix used for resources"
  value       = random_id.suffix.hex
}

output "s3_bucket_name" {
  description = "Name of the vulnerable S3 bucket"
  value       = aws_s3_bucket.sensitive_data.id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ec2_public_ip" {
  description = "Static Elastic IP of the Amazon Linux EC2 instance"
  value       = aws_eip.demo_app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the demo EC2 instance"
  value       = aws_eip.demo_app.public_dns
}

output "app_url" {
  description = "URL to access the vulnerable demo app"
  value       = "http://${aws_eip.demo_app.public_ip}:3000"
}

output "ec2_ubuntu_public_ip" {
  description = "Static Elastic IP of the Ubuntu EC2 instance"
  value       = aws_eip.demo_app_ubuntu.public_ip
}

output "ec2_ubuntu_public_dns" {
  description = "Public DNS of the Ubuntu demo EC2 instance"
  value       = aws_eip.demo_app_ubuntu.public_dns
}

output "app_url_ubuntu" {
  description = "URL to access the vulnerable demo app on Ubuntu (port 80)"
  value       = "http://${aws_eip.demo_app_ubuntu.public_ip}"
}

# -----------------------------------------------------------------------------
# EKS Outputs (only when enable_eks = true)
# -----------------------------------------------------------------------------
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API server"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = var.enable_eks ? module.eks[0].cluster_version : null
}

output "eks_kubeconfig_command" {
  description = "Command to configure kubectl for EKS"
  value       = var.enable_eks ? "aws eks update-kubeconfig --name ${module.eks[0].cluster_name} --region ${var.aws_region}" : null
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}
