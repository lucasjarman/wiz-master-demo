# Map of policies for for_each functionality
variable "policies" {
  description = "Map of Wiz CiCD scan policies to create. Each policy supports different scan types (IaC, Secrets, Vulnerabilities, Image Integrity, Sensitive Data, Host Configuration) with their respective parameters. Only one scan type parameter should be provided per policy. The key in the map will be used as the policy identifier."
  type = map(object({
    name                   = string
    description            = optional(string, "")
    project_ids            = optional(set(string), [])
    rule_lifecycle_targets = optional(set(string), [])
    default                = optional(bool, false)

    policy_lifecycle_enforcements = optional(list(object({
      deployment_lifecycle = string
      enforcement_method   = string
      enforcement_config = optional(object({
        admission_controller_config = optional(object({
          enforce_on_scope = optional(bool)
        }))
      }))
    })), [])

    iac_params = optional(object({
      iac_count_threshold         = number
      severity_threshold          = string
      ignored_rules               = optional(set(string), [])
      security_frameworks         = optional(set(string), [])
      builtin_ignore_tags_enabled = optional(bool)
      cloud_configuration_rules   = optional(set(string))
      custom_ignore_tags = optional(list(object({
        key              = string
        value            = optional(string)
        ignore_all_rules = optional(bool)
        rule_ids         = optional(set(string))
      })))
    }))

    disk_secrets_params = optional(object({
      secrets_count_threshold           = number
      path_allow_list                   = optional(set(string), [])
      secret_finding_severity_threshold = optional(string, "INFORMATIONAL")
    }))

    disk_vulnerabilities_params = optional(object({
      package_count_threshold           = number
      severity                          = string
      package_allow_list                = optional(set(string), [])
      detection_methods                 = optional(set(string), [])
      fix_grace_period_hours            = optional(number)
      publish_grace_period_hours        = optional(number)
      ignore_transitive_vulnerabilities = optional(bool, false)
      ignore_unfixed                    = optional(bool)
      vulnerability_ids                 = optional(set(string))
    }))

    image_integrity_params = optional(object({
      validators_ids = set(string)
      excluded_resource_tags = optional(list(object({
        key   = string
        value = optional(string)
      })))
      fail_images_without_validators = optional(bool)
    }))

    sensitive_data_params = optional(object({
      count_threshold    = number
      severity_threshold = string
    }))

    host_configuration_params = optional(object({
      rules_scope = object({
        type                = string
        security_frameworks = optional(set(string))
      })
      severity                  = string
      fail_count_threshold      = optional(number)
      pass_percentage_threshold = optional(number)
    }))
  }))
  default = {}

  # Basic validation for policy names
  validation {
    condition = alltrue([
      for policy_key, policy in var.policies : length(policy.name) > 0
    ])
    error_message = "Policy name cannot be empty."
  }

  validation {
    condition = alltrue([
      for policy_key, policy in var.policies : length(policy.name) <= 255
    ])
    error_message = "Policy name cannot exceed 255 characters."
  }
}
