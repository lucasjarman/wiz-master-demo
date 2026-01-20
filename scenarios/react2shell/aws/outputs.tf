################################################################################
# React2Shell RCE Demo Scenario - Outputs
################################################################################

output "s3_bucket_name" {
  description = "Name of the S3 bucket containing sensitive data"
  value       = aws_s3_bucket.sensitive_data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket containing sensitive data"
  value       = aws_s3_bucket.sensitive_data.arn
}

output "irsa_role_arn" {
  description = "ARN of the IRSA role for the vulnerable application"
  value       = module.react2shell_app.irsa_role_arn
}

output "app_namespace" {
  description = "Kubernetes namespace where the application is deployed"
  value       = module.react2shell_app.namespace
}

output "app_service_account_name" {
  description = "Service account name for the application"
  value       = module.react2shell_app.service_account_name
}

output "app_workload_name" {
  description = "Name of the Kubernetes workload (deployment)"
  value       = module.react2shell_app.deployment_name
}

# Note: NLB hostname must be retrieved via kubectl after deployment
# kubectl get svc <app_workload_name> -n <app_namespace> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
output "get_nlb_command" {
  description = "Command to get the NLB hostname after deployment"
  value       = "kubectl get svc ${module.react2shell_app.deployment_name} -n ${module.react2shell_app.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
