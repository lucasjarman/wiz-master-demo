# -----------------------------------------------------------------------------
# APPLICATION KUBERNETES SETUP
# -----------------------------------------------------------------------------
# Configures the Service Account for IRSA

resource "kubernetes_namespace" "app_ns" {
  count = var.enable_eks && var.enable_k8s_resources ? 1 : 0

  metadata {
    name = "wiz-demo"
    labels = {
      app         = "wiz-rsc-demo"
      environment = "demo"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_service_account" "app_sa" {
  count = var.enable_eks && var.enable_k8s_resources ? 1 : 0

  metadata {
    name      = "wiz-rsc-sa"
    namespace = kubernetes_namespace.app_ns[0].metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_s3_role[0].arn
    }
  }

  automount_service_account_token = true
  depends_on                      = [kubernetes_namespace.app_ns]
}
