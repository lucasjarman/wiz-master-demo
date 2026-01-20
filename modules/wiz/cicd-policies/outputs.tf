# Outputs for multiple policies (for_each mode)
output "policies" {
  description = "Map of all created scan policies with their details"
  value = {
    for k, v in wiz_cicd_scan_policy.policies : k => {
      id      = v.id
      name    = v.name
      type    = v.type
      builtin = v.builtin
      default = v.default
    }
  }
}

output "policy_ids" {
  description = "Map of policy names to their IDs"
  value = {
    for k, v in wiz_cicd_scan_policy.policies : k => v.id
  }
}

output "policy_names" {
  description = "Map of policy keys to their names"
  value = {
    for k, v in wiz_cicd_scan_policy.policies : k => v.name
  }
}

output "policy_types" {
  description = "Map of policy keys to their types"
  value = {
    for k, v in wiz_cicd_scan_policy.policies : k => v.type
  }
}
