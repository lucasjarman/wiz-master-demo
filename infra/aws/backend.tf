# -----------------------------------------------------------------------------
# Terraform S3 Backend Configuration
# -----------------------------------------------------------------------------
# This enables remote state storage in S3 with DynamoDB locking.
# Required for CI/CD and team collaboration.
#
# SETUP INSTRUCTIONS:
# 1. First, run the bootstrap to create the S3 bucket and DynamoDB table:
#      cd infra/bootstrap
#      terraform init
#      terraform apply
#
# 2. Then uncomment the backend block below and migrate state:
#      cd infra/aws
#      terraform init -migrate-state
#
# 3. Answer "yes" when prompted to copy existing state to the new backend.
# -----------------------------------------------------------------------------

# Uncomment after running bootstrap:
#
# terraform {
#   backend "s3" {
#     bucket         = "wiz-demo-terraform-state"
#     key            = "wiz-master-demo/terraform.tfstate"
#     region         = "ap-southeast-2"
#     dynamodb_table = "wiz-demo-terraform-locks"
#     encrypt        = true
#     profile        = "wiz-demo"
#   }
# }

