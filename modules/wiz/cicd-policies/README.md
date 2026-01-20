# cicd-policies

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | ~> 1.26 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_wiz"></a> [wiz](#provider\_wiz) | ~> 1.26 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| wiz_cicd_scan_policy.policies | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_policies"></a> [policies](#input\_policies) | Map of Wiz CiCD scan policies to create. Each policy supports different scan types (IaC, Secrets, Vulnerabilities, Image Integrity, Sensitive Data, Host Configuration) with their respective parameters. Only one scan type parameter should be provided per policy. The key in the map will be used as the policy identifier. | <pre>map(object({<br/>    name                   = string<br/>    description            = optional(string, "")<br/>    project_ids            = optional(set(string), [])<br/>    rule_lifecycle_targets = optional(set(string), [])<br/>    default                = optional(bool, false)<br/><br/>    policy_lifecycle_enforcements = optional(list(object({<br/>      deployment_lifecycle = string<br/>      enforcement_method   = string<br/>      enforcement_config = optional(object({<br/>        admission_controller_config = optional(object({<br/>          enforce_on_scope = optional(bool)<br/>        }))<br/>      }))<br/>    })), [])<br/><br/>    iac_params = optional(object({<br/>      iac_count_threshold         = number<br/>      severity_threshold          = string<br/>      ignored_rules               = optional(set(string), [])<br/>      security_frameworks         = optional(set(string), [])<br/>      builtin_ignore_tags_enabled = optional(bool)<br/>      cloud_configuration_rules   = optional(set(string))<br/>      custom_ignore_tags = optional(list(object({<br/>        key              = string<br/>        value            = optional(string)<br/>        ignore_all_rules = optional(bool)<br/>        rule_ids         = optional(set(string))<br/>      })))<br/>    }))<br/><br/>    disk_secrets_params = optional(object({<br/>      secrets_count_threshold           = number<br/>      path_allow_list                   = optional(set(string), [])<br/>      secret_finding_severity_threshold = optional(string, "INFORMATIONAL")<br/>    }))<br/><br/>    disk_vulnerabilities_params = optional(object({<br/>      package_count_threshold           = number<br/>      severity                          = string<br/>      package_allow_list                = optional(set(string), [])<br/>      detection_methods                 = optional(set(string), [])<br/>      fix_grace_period_hours            = optional(number)<br/>      publish_grace_period_hours        = optional(number)<br/>      ignore_transitive_vulnerabilities = optional(bool, false)<br/>      ignore_unfixed                    = optional(bool)<br/>      vulnerability_ids                 = optional(set(string))<br/>    }))<br/><br/>    image_integrity_params = optional(object({<br/>      validators_ids = set(string)<br/>      excluded_resource_tags = optional(list(object({<br/>        key   = string<br/>        value = optional(string)<br/>      })))<br/>      fail_images_without_validators = optional(bool)<br/>    }))<br/><br/>    sensitive_data_params = optional(object({<br/>      count_threshold    = number<br/>      severity_threshold = string<br/>    }))<br/><br/>    host_configuration_params = optional(object({<br/>      rules_scope = object({<br/>        type                = string<br/>        security_frameworks = optional(set(string))<br/>      })<br/>      severity                  = string<br/>      fail_count_threshold      = optional(number)<br/>      pass_percentage_threshold = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policies"></a> [policies](#output\_policies) | Map of all created scan policies with their details |
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | Map of policy names to their IDs |
| <a name="output_policy_names"></a> [policy\_names](#output\_policy\_names) | Map of policy keys to their names |
| <a name="output_policy_types"></a> [policy\_types](#output\_policy\_types) | Map of policy keys to their types |
<!-- END_TF_DOCS -->
