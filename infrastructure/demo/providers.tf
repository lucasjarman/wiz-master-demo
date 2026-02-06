# =============================================================================
# Providers - Single Root Module
# =============================================================================
# All providers configured here. Kubernetes/Helm providers use data sources
# that resolve after EKS is created.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Random provider for generating unique suffixes
provider "random" {}

# =============================================================================
# EKS Authentication Data Sources
# =============================================================================
# These data sources are used to configure the Kubernetes and Helm providers.
# They will fail on the first run before EKS exists, but that's OK because
# the K8s resources depend on the EKS module.

data "aws_eks_cluster" "this" {
  count = var.create_eks ? 1 : 0
  name  = module.eks[0].cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  count = var.create_eks ? 1 : 0
  name  = module.eks[0].cluster_name

  depends_on = [module.eks]
}

# =============================================================================
# Kubernetes Provider
# =============================================================================
provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.this[0].endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.this[0].token, null)
}

# =============================================================================
# Helm Provider
# =============================================================================
provider "helm" {
  kubernetes {
    host                   = try(data.aws_eks_cluster.this[0].endpoint, null)
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data), null)
    token                  = try(data.aws_eks_cluster_auth.this[0].token, null)
  }
}

# =============================================================================
# Kubectl Provider (for raw manifests)
# =============================================================================
provider "kubectl" {
  host                   = try(data.aws_eks_cluster.this[0].endpoint, null)
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data), null)
  token                  = try(data.aws_eks_cluster_auth.this[0].token, null)
  load_config_file       = false
}

# =============================================================================
# Wiz Provider
# =============================================================================
# Requires WIZ_CLIENT_ID and WIZ_CLIENT_SECRET environment variables
provider "wiz" {}
