################################################################################
# Wiz Tenant Configuration - Outputs
################################################################################

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.k8s_services.argocd_namespace
}

output "wiz_namespace" {
  description = "Wiz namespace"
  value       = module.k8s_services.wiz_namespace
}

output "kubernetes_connector_name" {
  description = "Wiz Kubernetes connector name"
  value       = module.k8s_services.kubernetes_connector_name
}

output "wiz_service_account_name" {
  description = "Name of the dynamically created Wiz service account"
  value       = wiz_service_account.eks_cluster.name
}

output "wiz_service_account_id" {
  description = "ID of the dynamically created Wiz service account"
  value       = wiz_service_account.eks_cluster.id
}

