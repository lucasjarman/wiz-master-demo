# -----------------------------------------------------------------------------
# APPLICATION KUBERNETES SETUP
# -----------------------------------------------------------------------------
# Configures the Service Account for IRSA

resource "kubernetes_service_account" "app_sa" {
  count = var.enable_eks ? 1 : 0

  metadata {
    name      = "wiz-rsc-sa"
    namespace = "wiz-demo"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_s3_role[0].arn
    }
  }

  automount_service_account_token = true
  depends_on                      = [module.eks]
}
