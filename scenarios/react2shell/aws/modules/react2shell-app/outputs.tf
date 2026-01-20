output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "service_account_name" {
  description = "Service account name"
  value       = local.service_account_name
}

output "irsa_role_arn" {
  description = "IAM role ARN for IRSA"
  value       = module.irsa_role.iam_role_arn
}

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = var.name
}
