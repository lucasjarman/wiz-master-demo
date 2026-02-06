# =============================================================================
# Main - Single Root Module for Wiz Demo
# =============================================================================
# This file orchestrates all components in a single terraform apply:
# - VPC + EKS cluster
# - ECR repository
# - Wiz AWS permissions (IAM role)
# - AWS Load Balancer Controller
# - Wiz K8s integration (Terraform-managed Helm release)
# - React2Shell demo scenario (app + S3 bucket + IRSA)
#
# Benefits:
# - One terraform apply / destroy (no ordering issues)
# - No remote state dependencies
# - Reliable for demos

locals {
  # Generate a random suffix for resource uniqueness
  suffix = random_id.this.hex

  # Resource naming - ALL resources use the suffix to avoid conflicts
  cluster_name = "${var.prefix}-${local.suffix}-eks"
  ecr_name     = "${var.prefix}-${local.suffix}-app"

  # Common tags
  tags = merge(var.common_tags, {
    Environment = var.environment
    Suffix      = local.suffix
  })
}

# Random ID for resource uniqueness
resource "random_id" "this" {
  byte_length = 3
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# VPC
# =============================================================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, 100 + i)]
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)]

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

# =============================================================================
# EKS Cluster
# =============================================================================
module "eks" {
  count   = var.create_eks ? 1 : 0
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

# =============================================================================
# Graceful Shutdown - Gives Kubernetes controllers time to clean up
# =============================================================================
# This is the key to avoiding orphaned resources (security groups, ENIs) on destroy.
# The destroy_duration gives the AWS LB Controller time to delete NLBs/ALBs and
# their associated security groups before the EKS cluster is destroyed.
resource "time_sleep" "wait_for_cluster" {
  count            = var.create_eks ? 1 : 0
  depends_on       = [module.eks]
  create_duration  = "10s"
  destroy_duration = "60s" # Increased from 30s for more reliable cleanup
}

# =============================================================================
# ECR Repository
# =============================================================================
resource "aws_ecr_repository" "app" {
  name                 = local.ecr_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}


# =============================================================================
# AWS Load Balancer Controller
# =============================================================================
module "aws_lb_controller_irsa_role" {
  count   = var.create_eks ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${local.cluster_name}-aws-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks[0].oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

resource "helm_release" "aws_load_balancer_controller" {
  count      = var.create_eks ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks[0].cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_lb_controller_irsa_role[0].iam_role_arn
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    time_sleep.wait_for_cluster, # Wait for cluster stability
    module.aws_lb_controller_irsa_role
  ]
}

# =============================================================================
# Wiz AWS Permissions (IAM Role for Wiz Connector)
# =============================================================================
module "wiz_aws_permissions" {
  count  = var.create_wiz_connector && var.wiz_trusted_arn != "" ? 1 : 0
  source = "../shared/aws/modules/wiz_aws_permissions_v2"

  role_name   = "develop-${local.suffix}-WizAccessRole-AWS"
  prefix      = "develop-${local.suffix}-"
  remote_arn  = var.wiz_trusted_arn
  external_id = var.wiz_tenant_id
  tags        = local.tags

  # Enable all scanning features for demo
  enable_lightsail_scanning        = false
  enable_data_scanning             = true
  enable_eks_scanning              = true
  enable_terraform_bucket_scanning = true # Required for Wiz Code-to-Cloud IaC mapping
  enable_cloud_cost_scanning       = false
  enable_defend_scanning           = true
}


# =============================================================================
# Wiz Service Account (for K8s Integration)
# =============================================================================
resource "wiz_service_account" "eks_cluster" {
  count = var.create_wiz_k8s_integration && var.create_eks ? 1 : 0
  name  = "${var.prefix}-${local.suffix}-eks-cluster"
  type  = "FIRST_PARTY"
}

# =============================================================================
# Wiz Kubernetes Integration (Direct Helm + Sensor + Admission Controller)
# =============================================================================
module "k8s_services" {
  count  = var.create_wiz_k8s_integration && var.create_eks ? 1 : 0
  source = "../../modules/k8s-services"

  prefix           = var.prefix
  random_prefix_id = local.suffix
  cluster_type     = "EKS"

  # Wiz credentials (dynamically created service account)
  wiz_k8s_integration_client_id       = wiz_service_account.eks_cluster[0].client_id
  wiz_k8s_integration_client_secret   = wiz_service_account.eks_cluster[0].client_secret
  wiz_k8s_integration_client_endpoint = var.wiz_client_environment

  # Wiz sensor configuration
  use_wiz_sensor           = var.wiz_sensor_enabled
  wiz_sensor_pull_username = var.tenant_image_pull_username
  wiz_sensor_pull_password = var.tenant_image_pull_password

  # Wiz admission controller
  use_wiz_admission_controller = var.wiz_admission_controller_enabled

  depends_on = [
    time_sleep.wait_for_cluster, # Wait for cluster stability
    helm_release.aws_load_balancer_controller
  ]
}


# =============================================================================
# Wiz Defend Logging - CloudTrail
# =============================================================================

# KMS Key for CloudTrail encryption
resource "aws_kms_key" "cloudtrail" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  description             = "KMS key for CloudTrail logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        }
      },
      {
        Sid    = "Allow CloudTrail to describe key"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "kms:DescribeKey"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to use key for SNS"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SNS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "cloudtrail" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  name          = "alias/${var.prefix}-${local.suffix}-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail[0].key_id
}

# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  bucket        = "${var.prefix}-${local.suffix}-cloudtrail-logs"
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail[0].arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.cloudtrail_logs[0].arn,
          "${aws_s3_bucket.cloudtrail_logs[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# SNS Topic for CloudTrail notifications
resource "aws_sns_topic" "cloudtrail_fanout" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  name              = "${var.prefix}-${local.suffix}-cloudtrail-fanout"
  kms_master_key_id = aws_kms_key.cloudtrail[0].id

  tags = local.tags
}

resource "aws_sns_topic_policy" "cloudtrail_fanout" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  arn = aws_sns_topic.cloudtrail_fanout[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.cloudtrail_fanout[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowS3Publish"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.cloudtrail_fanout[0].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.cloudtrail_logs[0].arn
          }
        }
      }
    ]
  })
}

# S3 Bucket Notification for CloudTrail logs (triggers SNS on object creation)
resource "aws_s3_bucket_notification" "cloudtrail_logs" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  topic {
    topic_arn = aws_sns_topic.cloudtrail_fanout[0].arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.cloudtrail_fanout]
}

# CloudTrail Trail with S3 Data Events
resource "aws_cloudtrail" "demo" {
  count = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0

  name                          = "${var.prefix}-${local.suffix}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs[0].id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true
  kms_key_id                    = aws_kms_key.cloudtrail[0].arn
  sns_topic_name                = aws_sns_topic.cloudtrail_fanout[0].arn

  # Capture S3 Data Events (object-level operations)
  advanced_event_selector {
    name = "Management events"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  advanced_event_selector {
    name = "S3 Data Events"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }

  tags = local.tags

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_sns_topic_policy.cloudtrail_fanout
  ]
}

# =============================================================================
# Wiz Defend Logging - Module Calls
# =============================================================================

# CloudTrail SQS Queue (via aws-cloud-events module)
module "aws_cloud_events" {
  count  = var.enabled_logs.cloudtrail && var.create_wiz_connector ? 1 : 0
  source = "../../modules/aws/aws-cloud-events"

  prefix                = "${var.prefix}-${local.suffix}"
  integration_type      = "CLOUDTRAIL"
  cloudtrail_arn        = aws_cloudtrail.demo[0].arn
  cloudtrail_bucket_arn = aws_s3_bucket.cloudtrail_logs[0].arn
  cloudtrail_kms_arn    = aws_kms_key.cloudtrail[0].arn

  # Use the SNS topic we created above (already encrypted with our KMS key)
  use_existing_sns_topic       = true
  sns_topic_arn                = aws_sns_topic.cloudtrail_fanout[0].arn
  sns_topic_encryption_enabled = false # SNS topic already encrypted via aws_sns_topic.cloudtrail_fanout

  # SQS encryption with same KMS key
  sqs_encryption_enabled = true
  sqs_encryption_key_arn = aws_kms_key.cloudtrail[0].arn

  # Wiz IAM role for bucket access
  wiz_access_role_arn = module.wiz_aws_permissions[0].role_arn
  wiz_access_is_role  = true # Explicitly set to avoid plan-time ARN parsing

  depends_on = [
    aws_cloudtrail.demo,
    module.wiz_aws_permissions
  ]
}

# Route53 DNS Query Logs (via wiz-defend-logging module)
module "wiz_defend_logs" {
  count  = var.enabled_logs.route53_logs && var.create_wiz_connector ? 1 : 0
  source = "../../modules/aws/wiz-defend-logging"

  prefix         = "${var.prefix}-${local.suffix}"
  wiz_role_names = { "demo" = module.wiz_aws_permissions[0].role_name }
  vpc_ids        = var.create_eks ? { "main" = module.vpc.vpc_id } : {}
  tags           = local.tags

  depends_on = [module.wiz_aws_permissions]
}

# =============================================================================
# Wiz AWS Connector
# =============================================================================
module "wiz_aws_connector" {
  count  = var.create_wiz_connector && var.wiz_trusted_arn != "" ? 1 : 0
  source = "../../modules/wiz/aws-connector"

  connector_name         = "${var.prefix}-${local.suffix}-aws-connector"
  customer_role_arn      = module.wiz_aws_permissions[0].role_arn
  skip_organization_scan = true

  # Enable cloud events for Wiz Defend
  audit_log_monitor_enabled   = var.enabled_logs.cloudtrail
  dns_log_monitor_enabled     = var.enabled_logs.route53_logs
  network_log_monitor_enabled = false # VPC Flow Logs not implemented

  # CloudTrail configuration with SQS queue URL
  cloud_trail_config = {
    bucket_name = var.enabled_logs.cloudtrail ? aws_s3_bucket.cloudtrail_logs[0].id : null
    notifications_sqs_options = var.enabled_logs.cloudtrail ? {
      region             = var.aws_region
      override_queue_url = module.aws_cloud_events[0].sqs_queue_url
    } : null
  }

  # Route53 DNS Query Logs configuration with SQS queue URL
  resolver_query_logs_config = {
    bucket_name = var.enabled_logs.route53_logs ? module.wiz_defend_logs[0].bucket_id : null
    notifications_sqs_options = var.enabled_logs.route53_logs ? {
      region             = var.aws_region
      override_queue_url = module.wiz_defend_logs[0].sqs_queue_urls["demo"]
    } : null
  }

  # Scan ALL buckets, not just public ones (required for demo sensitive data bucket)
  scheduled_scanning_settings = {
    enabled                         = true
    public_buckets_scanning_enabled = false
  }

  depends_on = [
    module.wiz_aws_permissions,
    module.aws_cloud_events,
    module.wiz_defend_logs
  ]
}

# =============================================================================
# React2Shell Scenario - S3 Bucket with Sensitive Data
# =============================================================================
resource "aws_s3_bucket" "sensitive_data" {
  count  = var.create_react2shell ? 1 : 0
  bucket = "${var.app_name}-${local.suffix}-sensitive-data"

  tags = merge(local.tags, {
    DataClassification = "Sensitive"
    Purpose            = "WizDemo"
    Scenario           = "react2shell"
  })
}

resource "aws_s3_bucket_public_access_block" "sensitive_data" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "sensitive_data" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload fake sensitive data files (triggers Wiz data findings)
resource "aws_s3_object" "customer_data" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id
  key    = "pii/customer-data.txt"
  source = "../../scenarios/react2shell/aws/data/customer-data.txt"
  etag   = filemd5("../../scenarios/react2shell/aws/data/customer-data.txt")
  tags   = local.tags
}

resource "aws_s3_object" "client_keys" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id
  key    = "pii/client_keys.txt"
  source = "../../scenarios/react2shell/aws/data/client_keys.txt"
  etag   = filemd5("../../scenarios/react2shell/aws/data/client_keys.txt")
  tags   = local.tags
}

resource "aws_s3_object" "aws_credentials" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id
  key    = "secrets/aws-credentials.txt"
  source = "../../scenarios/react2shell/aws/data/aws-credentials.txt"
  etag   = filemd5("../../scenarios/react2shell/aws/data/aws-credentials.txt")
  tags   = local.tags
}

resource "aws_s3_object" "api_keys" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id
  key    = "secrets/api-keys.txt"
  source = "../../scenarios/react2shell/aws/data/api-keys.txt"
  etag   = filemd5("../../scenarios/react2shell/aws/data/api-keys.txt")
  tags   = local.tags
}

resource "aws_s3_object" "customer_conversations" {
  count  = var.create_react2shell ? 1 : 0
  bucket = aws_s3_bucket.sensitive_data[0].id
  key    = "ai-training/customer-conversations.jsonl"
  source = "../../scenarios/react2shell/aws/data/customer-conversations.jsonl"
  etag   = filemd5("../../scenarios/react2shell/aws/data/customer-conversations.jsonl")
  tags   = local.tags
}

# =============================================================================
# React2Shell Application
# =============================================================================
module "react2shell_app" {
  count  = var.create_react2shell && var.create_eks ? 1 : 0
  source = "../../scenarios/react2shell/aws/modules/react2shell-app"

  name                      = "${var.app_name}-${local.suffix}"
  cluster_oidc_provider_arn = module.eks[0].oidc_provider_arn
  kubernetes_namespace      = "${var.app_name}-${local.suffix}"
  ecr_image                 = var.ecr_image != "" ? var.ecr_image : "${aws_ecr_repository.app.repository_url}:latest"
  replicas                  = var.app_replicas
  common_tags               = local.tags

  # NetworkPolicy configuration
  vpc_cidr          = module.vpc.vpc_cidr_block
  wiz_scanner_cidrs = var.dynamic_scanner_ipv4s_develop != "" ? [for cidr in split(",", var.dynamic_scanner_ipv4s_develop) : trimspace(cidr)] : []
  allowed_cidrs     = var.allowed_cidrs

  depends_on = [
    time_sleep.wait_for_cluster, # Wait for cluster stability
    helm_release.aws_load_balancer_controller
  ]
}
