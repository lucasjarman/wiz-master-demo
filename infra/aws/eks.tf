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

      # Attach our custom IAM policy for S3 access (lateral movement)
      iam_role_additional_policies = {
        s3_access = aws_iam_policy.eks_node_s3_access[0].arn
      }

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

# -----------------------------------------------------------------------------
# Security Group for EKS NLB (allow whitelisted IPs only)
# -----------------------------------------------------------------------------
resource "aws_security_group" "eks_nlb" {
  count = var.enable_eks ? 1 : 0

  name        = "wiz-demo-eks-nlb-sg-${random_id.suffix.hex}"
  description = "Security group for EKS NLB - whitelisted IPs only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from whitelisted IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "wiz-demo-eks-nlb-sg"
    Environment = "Demo"
  }
}

