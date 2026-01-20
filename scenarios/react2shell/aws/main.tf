# -----------------------------------------------------------------------------
# React2Shell Scenario (CVE-2025-66478)
# -----------------------------------------------------------------------------
# Demonstrates: Public Exposure + RCE Vulnerability + IRSA + Sensitive Data
# Attack Path: Internet → NLB → Pod (RCE) → ServiceAccount → IAM Role → S3

locals {
  backend_config_json = jsondecode(file(var.backend_config_json_path))
  environment         = local.backend_config_json.environment
  branch              = local.backend_config_json.branch
  suffix              = local.backend_config_json.suffix

  # Simple naming: react2shell-v1
  name = "${var.app_name}-${local.suffix}"
  # Note: Avoid duplicate tag keys (AWS IAM is case-insensitive)
  # common_tags already has "Environment", so only add unique tags here
  tags = merge(var.common_tags, {
    Branch   = local.branch
    Scenario = "react2shell"
  })
}

# -----------------------------------------------------------------------------
# Remote State - Reference Shared Infrastructure
# -----------------------------------------------------------------------------
data "terraform_remote_state" "shared_resources" {
  backend = "s3"
  config = {
    bucket = local.backend_config_json.state.bucket
    key    = "infrastructure/shared/aws/terraform.tfstate"
    region = local.backend_config_json.state.region
    # Credentials provided via environment variables (fnox + 1Password)
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket - Sensitive Data (Private)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "sensitive_data" {
  bucket = "${local.name}-sensitive-data"

  tags = merge(local.tags, {
    DataClassification = "Sensitive"
    Purpose            = "WizDemo"
  })
}

resource "aws_s3_bucket_public_access_block" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload fake sensitive data
resource "aws_s3_object" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id
  key    = "pii/customer_data.txt"
  source = "${path.module}/data/sensitive_data.txt"
  etag   = filemd5("${path.module}/data/sensitive_data.txt")

  tags = local.tags
}

# -----------------------------------------------------------------------------
# React2Shell Application Module
# -----------------------------------------------------------------------------
module "react2shell_app" {
  source = "./modules/react2shell-app"

  name                      = local.name
  cluster_oidc_provider_arn = data.terraform_remote_state.shared_resources.outputs.cluster_oidc_provider_arn
  kubernetes_namespace      = "${var.app_name}-${local.suffix}"
  ecr_image                 = var.ecr_image != "" ? var.ecr_image : "${data.terraform_remote_state.shared_resources.outputs.ecr_repository_url}:latest"
  replicas                  = var.app_replicas
  common_tags               = local.tags

  # NetworkPolicy configuration
  # SGs remain open (0.0.0.0/0) so Wiz evaluates "publicly exposed" risk
  # NetworkPolicy actually restricts traffic to allowed IPs only
  vpc_cidr          = data.terraform_remote_state.shared_resources.outputs.vpc_cidr_block
  wiz_scanner_cidrs = [for cidr in split(",", var.dynamic_scanner_ipv4s_develop) : trimspace(cidr)]
  allowed_cidrs     = var.allowed_cidrs
}
