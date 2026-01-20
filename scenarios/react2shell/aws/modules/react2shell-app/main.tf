locals {
  service_account_name = "${var.name}-sa"
}

# IRSA Role using terraform-aws-modules (modern approach)
module "irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-irsa-role"

  # Intentionally over-permissive for demo
  role_policy_arns = {
    s3_full_access = aws_iam_policy.s3_full_access.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["${var.kubernetes_namespace}:${local.service_account_name}"]
    }
  }

  tags = var.common_tags
}

# S3 full access policy (intentionally insecure for demo)
resource "aws_iam_policy" "s3_full_access" {
  name        = "${var.name}-s3-full-access"
  description = "Intentionally over-permissive S3 access for Wiz demo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3FullAccess"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# Kubernetes namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.kubernetes_namespace
    labels = {
      app         = var.name
      environment = "demo"
    }
  }
}

# Service Account with IRSA annotation
resource "kubectl_manifest" "service_account" {
  yaml_body = templatefile("${path.module}/manifests/serviceaccount.yaml", {
    service_account_name = local.service_account_name
    namespace            = kubernetes_namespace.app.metadata[0].name
    irsa_role_arn        = module.irsa_role.iam_role_arn
  })

  depends_on = [kubernetes_namespace.app]
}

# Deploy the app using kubectl_manifest with templated YAML
resource "kubectl_manifest" "deployment" {
  yaml_body = templatefile("${path.module}/manifests/deployment.yaml", {
    name                 = var.name
    namespace            = kubernetes_namespace.app.metadata[0].name
    service_account_name = local.service_account_name
    ecr_image            = var.ecr_image
    replicas             = var.replicas
  })

  # Don't wait for rollout - causes hangs when only metadata changes
  wait_for_rollout = false

  depends_on = [kubectl_manifest.service_account]
}

resource "kubectl_manifest" "service" {
  yaml_body = templatefile("${path.module}/manifests/service.yaml", {
    name      = var.name
    namespace = kubernetes_namespace.app.metadata[0].name
  })

  depends_on = [kubectl_manifest.deployment]
}

# NetworkPolicy - allows Wiz scanners + custom IPs while keeping SGs open
# This creates the appearance of "publicly exposed" in Wiz while actually
# restricting traffic at the pod level
resource "kubectl_manifest" "network_policy" {
  yaml_body = templatefile("${path.module}/manifests/network-policy.yaml", {
    name          = var.name
    namespace     = kubernetes_namespace.app.metadata[0].name
    vpc_cidr      = var.vpc_cidr
    allowed_cidrs = concat(var.wiz_scanner_cidrs, var.allowed_cidrs)
  })

  depends_on = [kubernetes_namespace.app]
}
