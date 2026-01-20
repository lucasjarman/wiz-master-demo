# Multiple policies using for_each
resource "wiz_cicd_scan_policy" "policies" {
  for_each = var.policies

  name                   = each.value.name
  description            = each.value.description
  project_ids            = each.value.project_ids
  rule_lifecycle_targets = each.value.rule_lifecycle_targets
  default                = each.value.default

  # Policy lifecycle enforcements
  dynamic "policy_lifecycle_enforcements" {
    for_each = each.value.policy_lifecycle_enforcements
    content {
      deployment_lifecycle = policy_lifecycle_enforcements.value.deployment_lifecycle
      enforcement_method   = policy_lifecycle_enforcements.value.enforcement_method

      dynamic "enforcement_config" {
        for_each = policy_lifecycle_enforcements.value.enforcement_config != null ? [policy_lifecycle_enforcements.value.enforcement_config] : []
        content {
          dynamic "admission_controller_config" {
            for_each = enforcement_config.value.admission_controller_config != null ? [enforcement_config.value.admission_controller_config] : []
            content {
              enforce_on_scope = admission_controller_config.value.enforce_on_scope
            }
          }
        }
      }
    }
  }

  dynamic "iac_params" {
    for_each = each.value.iac_params != null ? [each.value.iac_params] : []
    content {
      iac_count_threshold         = iac_params.value.iac_count_threshold
      severity_threshold          = iac_params.value.severity_threshold
      ignored_rules               = iac_params.value.ignored_rules
      security_frameworks         = iac_params.value.security_frameworks
      builtin_ignore_tags_enabled = iac_params.value.builtin_ignore_tags_enabled
      cloud_configuration_rules   = iac_params.value.cloud_configuration_rules

      dynamic "custom_ignore_tags" {
        for_each = iac_params.value.custom_ignore_tags != null ? iac_params.value.custom_ignore_tags : []
        content {
          key              = custom_ignore_tags.value.key
          value            = custom_ignore_tags.value.value
          ignore_all_rules = custom_ignore_tags.value.ignore_all_rules
          rule_ids         = custom_ignore_tags.value.rule_ids
        }
      }
    }
  }

  dynamic "disk_secrets_params" {
    for_each = each.value.disk_secrets_params != null ? [each.value.disk_secrets_params] : []
    content {
      secrets_count_threshold           = disk_secrets_params.value.secrets_count_threshold
      path_allow_list                   = disk_secrets_params.value.path_allow_list
      secret_finding_severity_threshold = disk_secrets_params.value.secret_finding_severity_threshold
    }
  }

  dynamic "disk_vulnerabilities_params" {
    for_each = each.value.disk_vulnerabilities_params != null ? [each.value.disk_vulnerabilities_params] : []
    content {
      package_count_threshold           = disk_vulnerabilities_params.value.package_count_threshold
      severity                          = disk_vulnerabilities_params.value.severity
      package_allow_list                = disk_vulnerabilities_params.value.package_allow_list
      detection_methods                 = disk_vulnerabilities_params.value.detection_methods
      fix_grace_period_hours            = disk_vulnerabilities_params.value.fix_grace_period_hours
      publish_grace_period_hours        = disk_vulnerabilities_params.value.publish_grace_period_hours
      ignore_transitive_vulnerabilities = disk_vulnerabilities_params.value.ignore_transitive_vulnerabilities
      ignore_unfixed                    = disk_vulnerabilities_params.value.ignore_unfixed
      vulnerability_ids                 = disk_vulnerabilities_params.value.vulnerability_ids
    }
  }

  dynamic "image_integrity_params" {
    for_each = each.value.image_integrity_params != null ? [each.value.image_integrity_params] : []
    content {
      validators_ids                 = image_integrity_params.value.validators_ids
      fail_images_without_validators = image_integrity_params.value.fail_images_without_validators

      dynamic "excluded_resource_tags" {
        for_each = image_integrity_params.value.excluded_resource_tags != null ? image_integrity_params.value.excluded_resource_tags : []
        content {
          key   = excluded_resource_tags.value.key
          value = excluded_resource_tags.value.value
        }
      }
    }
  }

  dynamic "sensitive_data_params" {
    for_each = each.value.sensitive_data_params != null ? [each.value.sensitive_data_params] : []
    content {
      count_threshold    = sensitive_data_params.value.count_threshold
      severity_threshold = sensitive_data_params.value.severity_threshold
    }
  }

  dynamic "host_configuration_params" {
    for_each = each.value.host_configuration_params != null ? [each.value.host_configuration_params] : []
    content {
      rules_scope {
        type                = host_configuration_params.value.rules_scope.type
        security_frameworks = host_configuration_params.value.rules_scope.security_frameworks
      }
      severity                  = host_configuration_params.value.severity
      fail_count_threshold      = host_configuration_params.value.fail_count_threshold
      pass_percentage_threshold = host_configuration_params.value.pass_percentage_threshold
    }
  }
}
