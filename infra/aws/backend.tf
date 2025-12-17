# -----------------------------------------------------------------------------
# Terraform S3 Backend Configuration
# -----------------------------------------------------------------------------
# Remote state storage in S3 with DynamoDB locking.
# Created by running: cd infra/bootstrap && terraform apply
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "wiz-demo-tfstate-lucasjarman"
    key            = "wiz-master-demo/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "wiz-demo-terraform-locks"
    encrypt        = true
    profile        = "wiz-demo"
  }
}

