################################################################################
# React2Shell RCE Demo Scenario - Provider Configuration
################################################################################

provider "aws" {
  region = var.aws_region
  # Credentials provided via environment variables (fnox + 1Password)

  default_tags {
    tags = local.tags
  }
}

# Kubernetes provider configured via shared EKS cluster
provider "kubernetes" {
  host                   = data.terraform_remote_state.shared_resources.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.shared_resources.outputs.eks_cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.shared_resources.outputs.eks_cluster_name]
  }
}

# kubectl provider for raw manifest deployment
provider "kubectl" {
  host                   = data.terraform_remote_state.shared_resources.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.shared_resources.outputs.eks_cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.shared_resources.outputs.eks_cluster_name]
  }
  load_config_file = false
}

