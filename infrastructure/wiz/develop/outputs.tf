################################################################################
# Wiz Tenant Configuration - Outputs
################################################################################

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = try(module.k8s_services[0].argocd_namespace, null)
}

output "wiz_namespace" {
  description = "Wiz namespace"
  value       = try(module.k8s_services[0].wiz_namespace, null)
}

output "kubernetes_connector_name" {
  description = "Wiz Kubernetes connector name"
  value       = try(module.k8s_services[0].kubernetes_connector_name, null)
}

output "wiz_service_account_name" {
  description = "Name of the dynamically created Wiz service account"
  value       = wiz_service_account.eks_cluster.name
}

output "wiz_service_account_id" {
  description = "ID of the dynamically created Wiz service account"
  value       = wiz_service_account.eks_cluster.id
}

# -----------------------------------------------------------------------------
# AWS Connector Outputs
# -----------------------------------------------------------------------------
output "aws_connector_id" {
  description = "ID of the Wiz AWS Cloud Connector"
  value       = try(module.wiz_aws_connector[0].id, null)
}

output "aws_connector_name" {
  description = "Name of the Wiz AWS Cloud Connector"
  value       = try(module.wiz_aws_connector[0].name, null)
}

