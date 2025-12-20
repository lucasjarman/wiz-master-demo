# -----------------------------------------------------------------------------
# EKS CLUSTER (OPTIONAL - enabled via enable_eks variable)
# -----------------------------------------------------------------------------
# This deploys EKS alongside the existing EC2 setup for the Wiz demo.
# Attack path: Internet → NLB → EKS Pod (RCE) → IMDS → Node IAM Role → S3

locals {
  eks_cluster_name = "wiz-rsc-demo-eks-${random_id.suffix.hex}"
}

# -----------------------------------------------------------------------------
# EKS Cluster using terraform-aws-modules/eks/aws
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  count = var.enable_eks ? 1 : 0

  # v21 renamed: cluster_name -> name, cluster_version -> kubernetes_version
  name               = local.eks_cluster_name
  kubernetes_version = var.eks_cluster_version

  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow public access to cluster endpoint for demo simplicity
  # v21 renamed: cluster_endpoint_public_access -> endpoint_public_access
  endpoint_public_access = true

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # Enable IRSA (OIDC Provider) for Service Accounts
  enable_irsa = true

  # Control plane logging for Wiz visibility
  enabled_log_types = ["api", "audit", "authenticator"]

  # Required EKS Addons - these are NOT installed by default in v21
  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
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
    demo = {
      name           = "wiz-demo-nodes"
      instance_types = [var.eks_node_instance_type]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      # Use the custom launch template for IMDSv1
      use_custom_launch_template = true

      # INTENTIONAL VULNERABILITY: IMDSv1 enabled for credential theft demo
      # http_tokens = "optional" allows IMDSv1 (no token required)
      # hop_limit = 2 allows containers to reach IMDS
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "optional"
        http_put_response_hop_limit = 2
      }

      # REMOVED: Node-level S3 access. 
      # Now using IRSA (Pod-level access) to satisfy Wiz Graph Control requirements.
      # iam_role_additional_policies = {
      #   s3_access = aws_iam_policy.eks_node_s3_access[0].arn
      # }

      # Labels for easy identification
      labels = {
        Environment = "Demo"
        Project     = "React2Shell"
      }

      tags = {
        Environment = "Demo"
        Project     = "React2Shell"
      }
    }
  }

  tags = {
    Environment = "Demo"
    Project     = "React2Shell"
  }
}

# -----------------------------------------------------------------------------
# IRSA: IAM Role for Service Account (Pod Identity)
# -----------------------------------------------------------------------------
# Trust policy allowing the OIDC provider to assume this role
# Scope: system:serviceaccount:wiz-demo:wiz-rsc-sa
data "aws_iam_policy_document" "oidc_assume_role" {
  count = var.enable_eks ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks[0].oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks[0].oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks[0].oidc_provider}:sub"
      values   = ["system:serviceaccount:wiz-demo:wiz-rsc-sa"]
    }
  }
}

resource "aws_iam_role" "irsa_s3_role" {
  count = var.enable_eks ? 1 : 0

  name               = "wiz-rsc-sa-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role[0].json

  tags = {
    Environment = "Demo"
    Project     = "React2Shell"
    Type        = "IRSA"
  }
}

resource "aws_iam_role_policy_attachment" "irsa_s3_access" {
  count = var.enable_eks ? 1 : 0

  policy_arn = aws_iam_policy.eks_node_s3_access[0].arn
  role       = aws_iam_role.irsa_s3_role[0].name
}

# INTENTIONAL VULNERABILITY: AdministratorAccess for Demo Reliability
# Ensures Wiz Graph immediately draws "High Privilege" links.
resource "aws_iam_role_policy_attachment" "irsa_admin_access" {
  count = var.enable_eks ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.irsa_s3_role[0].name
}

# -----------------------------------------------------------------------------
# EKS Node IAM Policy for S3 Access (Lateral Movement)
# -----------------------------------------------------------------------------
# INTENTIONAL VULNERABILITY: Over-permissive IAM - same as EC2 role
resource "aws_iam_policy" "eks_node_s3_access" {
  count = var.enable_eks ? 1 : 0

  name        = "wiz-demo-eks-node-s3-access-${random_id.suffix.hex}"
  description = "Allow EKS nodes to read sensitive S3 bucket (intentionally over-permissive)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:ListAllMyBuckets"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.sensitive_data.arn,
          "${aws_s3_bucket.sensitive_data.arn}/*",
          "arn:aws:s3:::*"
        ]
      }
    ]
  })

  tags = {
    Environment   = "Demo"
    Vulnerability = "OverPermissive"
  }
}



