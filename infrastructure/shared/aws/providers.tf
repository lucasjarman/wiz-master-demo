# Provider Configuration

provider "aws" {
  region = var.aws_region
  # Credentials provided via environment variables (fnox + 1Password)
  # Or fallback to AWS profile if AWS_ACCESS_KEY_ID is not set

  default_tags {
    tags = local.tags
  }
}

# NOTE: Kubernetes and Helm providers have been moved to infrastructure/wiz/develop layer
# They are configured via terraform_remote_state to read EKS cluster outputs from this layer.

