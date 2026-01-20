# -----------------------------------------------------------------------------
# Shared AWS Infrastructure
# -----------------------------------------------------------------------------
# Creates shared resources that scenarios depend on:
# - VPC with public/private subnets
# - EKS cluster with IRSA enabled
# - ECR repository for container images

locals {
  backend_config_json = jsondecode(file(var.backend_config_json_path))
  environment         = local.backend_config_json.environment
  branch              = local.backend_config_json.branch
  suffix              = local.backend_config_json.suffix

  tags = merge(var.common_tags, {
    Branch = local.branch
  })

  # Simple naming: wiz-demo-eks, wiz-demo-app
  name             = var.prefix
  global_name      = "${var.prefix}-${local.suffix}"
  cluster_name     = "${var.prefix}-eks"
  random_prefix_id = local.suffix # For backwards compatibility with outputs

  # Map tenant names to Wiz role names (used for SQS queue creation per tenant)
  wiz_role_names = {
    for tenant_name, data in local.wiz_tenant_trust_data :
    tenant_name => "${tenant_name}-${local.suffix}-WizAccessRole-AWS"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets  = [for i, az in ["a", "b", "c"] : cidrsubnet(var.vpc_cidr, 8, 100 + i)]
  private_subnets = [for i, az in ["a", "b", "c"] : cidrsubnet(var.vpc_cidr, 8, i)]

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost optimization for demo
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS to discover subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Public endpoint for demo simplicity
  cluster_endpoint_public_access = true

  # Enable IRSA
  enable_irsa = true

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # Control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  # EKS Addons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # Managed node group
  eks_managed_node_groups = {
    default = {
      name           = "demo-nodes"
      instance_types = [var.eks_node_instance_type]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Custom launch template for IMDSv1 (demo vulnerability)
      use_custom_launch_template = true

      # INTENTIONAL VULNERABILITY: IMDSv1 enabled for credential theft demo
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "optional"
        http_put_response_hop_limit = 2
      }

      labels = {
        Environment = "Demo"
        Project     = "React2Shell"
      }

      tags = local.tags
    }
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = "${local.name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Wiz AWS Permissions (IAM Role for Wiz Connector)
# -----------------------------------------------------------------------------
# Creates the IAM role that Wiz will assume to scan this AWS account.
# The role trusts the Wiz AssumeRoleDelegator ARN (wiz_trusted_arn).

locals {
  # Support for single-tenant simplified setup
  # When wiz_trusted_arn is set, create permissions for a single "develop" tenant
  wiz_tenant_trust_data = var.wiz_trusted_arn != "" ? {
    "develop" = {
      tenant_id = var.wiz_tenant_id
      role      = var.wiz_trusted_arn
    }
  } : {}
}

module "wiz_aws_permissions" {
  for_each                         = local.wiz_tenant_trust_data
  source                           = "./modules/wiz_aws_permissions_v2"
  role_name                        = "${each.key}-${local.suffix}-WizAccessRole-AWS"
  prefix                           = "${each.key}-${local.suffix}-"
  enable_lightsail_scanning        = var.wiz_aws_connector_config.lightsail_scanning_enabled
  enable_data_scanning             = var.wiz_aws_connector_config.data_scanning_enabled
  enable_eks_scanning              = var.wiz_aws_connector_config.eks_scanning_enabled
  enable_terraform_bucket_scanning = var.wiz_aws_connector_config.terraform_scanning_enabled
  enable_cloud_cost_scanning       = var.wiz_aws_connector_config.cloud_cost_scanning_enabled
  enable_defend_scanning           = var.wiz_aws_connector_config.defend_scanning_enabled
  remote_arn                       = each.value.role
  external_id                      = each.value.tenant_id
  tags                             = var.common_tags
}

# NOTE: Kubernetes Services (ArgoCD + Wiz Integration) have been moved to
# infrastructure/wiz/develop layer to match wiz-demo-infra reference pattern.
# The wiz layer uses terraform_remote_state to read cluster outputs from this layer
# and creates wiz_service_account resources dynamically via the Wiz Terraform provider.

# NOTE: Wiz Defend Logging Infrastructure (CloudTrail, VPC Flow Logs, S3 buckets,
# SNS topics, SQS queues) is defined in wiz-defend-logging.tf
