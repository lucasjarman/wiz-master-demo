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
