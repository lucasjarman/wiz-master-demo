output "bucket_name" {
  value = local.cost_bucket_name
}

output "cost_export_prefix" {
  value = local.cost_export_prefix
}

output "cost_export_name" {
  value = local.cost_export_name
}

output "cost_policy_arn" {
  value = aws_iam_policy.wiz_allow_cost_export_bucket_access.arn
}
