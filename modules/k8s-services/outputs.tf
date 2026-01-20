output "argocd_url" {
  description = "The ArgoCD LoadBalancer hostname"
  value       = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
}

output "argocd_password" {
  description = "The ArgoCD admin password"
  value       = data.kubernetes_secret.argocd_initial_admin_secret.data["password"]
  sensitive   = true
}

output "kubernetes_connector_name" {
  description = "The Wiz Kubernetes connector name"
  value       = local.kubernetes_connector_name
}

output "argocd_namespace" {
  description = "The ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "wiz_namespace" {
  description = "The Wiz namespace"
  value       = kubernetes_namespace.wiz.metadata[0].name
}

