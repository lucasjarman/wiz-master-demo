locals {
  kubernetes_connector_name = "${var.prefix}-${var.random_prefix_id}-connector"
}

# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Wiz Namespace
resource "kubernetes_namespace" "wiz" {
  metadata {
    name = "wiz"
  }
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
}

# Data source to get ArgoCD admin password from secret
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

# Data source to get ArgoCD server LoadBalancer hostname
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

# Wiz integration deployed as ArgoCD Application using bedag/raw Helm chart
resource "helm_release" "wiz_argocd_application" {
  name       = "wiz-argocd-application"
  repository = "https://bedag.github.io/helm-charts"
  chart      = "raw"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "2.0.0"

  values = [
    templatefile("${path.module}/wiz_values.yaml", {
      kubernetes_namespace_argocd           = kubernetes_namespace.argocd.metadata[0].name
      kubernetes_namespace_wiz              = kubernetes_namespace.wiz.metadata[0].name
      kubernetes_connector_name             = local.kubernetes_connector_name
      cluster_type                          = var.cluster_type
      wiz_k8s_integration_client_id         = var.wiz_k8s_integration_client_id
      wiz_k8s_integration_client_secret     = var.wiz_k8s_integration_client_secret
      wiz_k8s_integration_client_endpoint   = var.wiz_k8s_integration_client_endpoint
      use_wiz_sensor                        = var.use_wiz_sensor
      wiz_sensor_pull_username              = var.wiz_sensor_pull_username
      wiz_sensor_pull_password              = var.wiz_sensor_pull_password
      use_wiz_admission_controller          = var.use_wiz_admission_controller
    })
  ]

  depends_on = [helm_release.argocd]
}

