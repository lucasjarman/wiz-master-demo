output "role_arn" {
  value       = aws_iam_role.user_role_tf.arn
  description = "Wiz Access Role ARN"
}

output "role_name" {
  value       = aws_iam_role.user_role_tf.name
  description = "Wiz Access Role Name"
}

output "enabled_policy_types" {
  value       = join(", ", keys(local.enabled_policies))
  description = "List of enabled policy types"
}

output "latest_policy_modification_date" {
  value       = local.latest_modified_date
  description = "Latest modification date of the policies"
}
