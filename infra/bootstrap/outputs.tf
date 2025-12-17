# -----------------------------------------------------------------------------
# Bootstrap Outputs
# -----------------------------------------------------------------------------
# These values are used in the main Terraform config's backend.tf

output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "S3 bucket ARN for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Backend configuration to add to infra/aws/backend.tf"
  value       = <<-EOT
    
    # Add this to infra/aws/backend.tf:
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "wiz-master-demo/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
        profile        = "${var.aws_profile}"
      }
    }
    
    # Then run: terraform init -migrate-state
    
  EOT
}

