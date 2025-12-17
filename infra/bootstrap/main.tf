# -----------------------------------------------------------------------------
# BOOTSTRAP - Terraform State Backend
# -----------------------------------------------------------------------------
# This creates the S3 bucket and DynamoDB table for Terraform remote state.
# Run this ONCE with local state before migrating the main config.
#
# Usage:
#   cd infra/bootstrap
#   terraform init
#   terraform apply
#
# Then migrate main config:
#   cd ../aws
#   terraform init -migrate-state
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  # This bootstrap config uses LOCAL state (intentionally)
  # The S3 bucket it creates will be used by the main config
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "wiz-demo"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "wiz-demo-tfstate-lucasjarman"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "wiz-demo-terraform-locks"
}

# -----------------------------------------------------------------------------
# S3 Bucket for Terraform State
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning for state history/recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# DynamoDB Table for State Locking
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

