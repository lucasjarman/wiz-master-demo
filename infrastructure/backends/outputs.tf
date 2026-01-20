output "backend_config" {
  description = "Backend configuration for use in other Terraform configurations"
  value = {
    bucket = aws_s3_bucket.state.id
    region = var.aws_region
  }
}

output "random_id" {
  description = "Random ID suffix used for unique bucket naming"
  value       = random_id.state_suffix.hex
}
