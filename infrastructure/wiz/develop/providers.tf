################################################################################
# Wiz Tenant Configuration - Provider Configuration
################################################################################

provider "aws" {
  region = var.aws_region

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

# Helm provider for ArgoCD and Wiz deployments
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.shared_resources.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.shared_resources.outputs.eks_cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.shared_resources.outputs.eks_cluster_name]
    }
  }
}

# Wiz provider - authenticates via WIZ_CLIENT_ID and WIZ_CLIENT_SECRET env vars
provider "wiz" {}

