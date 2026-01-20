# Wiz AWS Connector Module

This module creates and configures a Wiz connector for AWS environments, enabling security scanning and monitoring:

- AWS account integration
- IAM role configuration
- Security scanning settings
- Audit log monitoring
- CloudTrail integration

## Features
- Organization and account scanning
- Region-specific scanning configuration
- Scheduled security scanning
- Public bucket scanning
- Outpost integration for workload scanning
- Exclusion support for specific accounts or OUs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | >= 1.21 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_wiz"></a> [wiz](#provider\_wiz) | >= 1.21 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| wiz_aws_connector.connector | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_audit_log_monitor_enabled"></a> [audit\_log\_monitor\_enabled](#input\_audit\_log\_monitor\_enabled) | Boolean that controls whether the audit log monitor is enabled or disabled | `bool` | `false` | no |
| <a name="input_cloud_trail_config"></a> [cloud\_trail\_config](#input\_cloud\_trail\_config) | Map that contains the settings for scheduled security tool scanning.<br/>    bucket\_name: Name of the bucket where the CloudTrail logs are stored<br/>    bucket\_sub\_account: Account ID of the sub-account where the bucket is located<br/>    trail\_org: Organization associated with the trail | <pre>object({<br/>    bucket_name        = optional(string, null)<br/>    bucket_sub_account = optional(string, null)<br/>    trail_org          = optional(string, null)<br/>    notifications_sqs_options = optional(object({<br/>      region             = string<br/>      override_queue_url = string<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_connector_name"></a> [connector\_name](#input\_connector\_name) | Name that will be used for the connector | `string` | n/a | yes |
| <a name="input_connector_state"></a> [connector\_state](#input\_connector\_state) | Boolean that controls whether the connector is enabled or disabled | `bool` | `true` | no |
| <a name="input_customer_role_arn"></a> [customer\_role\_arn](#input\_customer\_role\_arn) | The ARN of the role that will be assumed by the connector | `string` | n/a | yes |
| <a name="input_disk_analyzer_scanner_arn"></a> [disk\_analyzer\_scanner\_arn](#input\_disk\_analyzer\_scanner\_arn) | The scanner role that will be used by the Wiz Outpost to perform workload scanning. | `string` | `null` | no |
| <a name="input_dns_log_monitor_enabled"></a> [dns\_log\_monitor\_enabled](#input\_dns\_log\_monitor\_enabled) | Boolean that controls whether the DNS log monitor is enabled or disabled | `bool` | `false` | no |
| <a name="input_excluded_accounts"></a> [excluded\_accounts](#input\_excluded\_accounts) | List of AWS account IDs that will be excluded from workload scanning | `set(string)` | `[]` | no |
| <a name="input_excluded_organization_units"></a> [excluded\_organization\_units](#input\_excluded\_organization\_units) | List of organization unit IDs that will be excluded from workload scanning | `set(string)` | `[]` | no |
| <a name="input_network_log_monitor_enabled"></a> [network\_log\_monitor\_enabled](#input\_network\_log\_monitor\_enabled) | Boolean that controls whether the network log monitor is enabled or disabled | `bool` | `false` | no |
| <a name="input_outpost_id"></a> [outpost\_id](#input\_outpost\_id) | The ID of the that will be used by the connector. | `string` | `null` | no |
| <a name="input_resolver_query_logs_config"></a> [resolver\_query\_logs\_config](#input\_resolver\_query\_logs\_config) | Map that contains the settings for DNS Resolver Query Logs.<br/>    bucket\_name: Name of the bucket where the DNS Resolver Query Logs are stored<br/>    notifications\_sqs\_options: Map that contains the settings for SQS notifications<br/>    region: AWS region where the SQS queue is located<br/>    override\_queue\_url: Optional URL to override the default SQS queue URL | <pre>object({<br/>    bucket_name = optional(string, null)<br/>    notifications_sqs_options = optional(object({<br/>      region             = string<br/>      override_queue_url = string<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_scan_regions"></a> [scan\_regions](#input\_scan\_regions) | List of regions that will be opted into workload scanning. If empty, all regions will be opted in | `set(string)` | `[]` | no |
| <a name="input_scheduled_scanning_settings"></a> [scheduled\_scanning\_settings](#input\_scheduled\_scanning\_settings) | Map that contains the settings for scheduled security tool scanning.<br/>    enabled: Boolean that controls whether the scheduled security tool scanning is enabled or disabled<br/>    public\_buckets\_scanning\_enabled: Boolean that controls whether public buckets scanning is enabled or disabled | <pre>object({<br/>    enabled                         = optional(bool, true)<br/>    public_buckets_scanning_enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_skip_organization_scan"></a> [skip\_organization\_scan](#input\_skip\_organization\_scan) | Boolean that controls whether the connector is scoped to a single account or an organization | `bool` | `false` | no |
| <a name="input_vpc_flow_log_config"></a> [vpc\_flow\_log\_config](#input\_vpc\_flow\_log\_config) | Map that contains the settings for VPC Flow Logs.<br/>    bucket\_name: Name of the bucket where the VPC Flow Logs are stored<br/>    notifications\_sqs\_options: Map that contains the settings for SQS notifications<br/>    region: AWS region where the SQS queue is located<br/>    override\_queue\_url: Optional URL to override the default SQS queue URL | <pre>object({<br/>    bucket_name = optional(string, null)<br/>    notifications_sqs_options = optional(object({<br/>      region             = string<br/>      override_queue_url = string<br/>    }))<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the connector that was created |
| <a name="output_name"></a> [name](#output\_name) | Name of the connector that was created |
| <a name="output_outpost_id"></a> [outpost\_id](#output\_outpost\_id) | ID of the Wiz Outpost that was used for this connector |
<!-- END_TF_DOCS -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.4.0 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | >= 1.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_wiz"></a> [wiz](#provider\_wiz) | >= 1.8 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| wiz_aws_connector.connector | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connector_name"></a> [connector\_name](#input\_connector\_name) | Name that will be used for the connector | `string` | n/a | yes |
| <a name="input_customer_role_arn"></a> [customer\_role\_arn](#input\_customer\_role\_arn) | The ARN of the role that will be assumed by the connector | `string` | n/a | yes |
| <a name="input_audit_log_monitor_enabled"></a> [audit\_log\_monitor\_enabled](#input\_audit\_log\_monitor\_enabled) | Boolean that controls whether the audit log monitor is enabled or disabled | `bool` | `false` | no |
| <a name="input_cloud_trail_config"></a> [cloud\_trail\_config](#input\_cloud\_trail\_config) | Map that contains the settings for scheduled security tool scanning.<br/>    bucket\_name: Name of the bucket where the CloudTrail logs are stored<br/>    bucket\_sub\_account: Account ID of the sub-account where the bucket is located<br/>    trail\_org: Organization associated with the trail | <pre>object({<br/>    bucket_name        = optional(string, null)<br/>    bucket_sub_account = optional(string, null)<br/>    trail_org          = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_connector_state"></a> [connector\_state](#input\_connector\_state) | Boolean that controls whether the connector is enabled or disabled | `bool` | `true` | no |
| <a name="input_disk_analyzer_scanner_arn"></a> [disk\_analyzer\_scanner\_arn](#input\_disk\_analyzer\_scanner\_arn) | The scanner role that will be used by the Wiz Outpost to perform workload scanning. | `string` | `null` | no |
| <a name="input_excluded_accounts"></a> [excluded\_accounts](#input\_excluded\_accounts) | List of AWS account IDs that will be excluded from workload scanning | `set(string)` | `[]` | no |
| <a name="input_excluded_organization_units"></a> [excluded\_organization\_units](#input\_excluded\_organization\_units) | List of organization unit IDs that will be excluded from workload scanning | `set(string)` | `[]` | no |
| <a name="input_outpost_id"></a> [outpost\_id](#input\_outpost\_id) | The ID of the that will be used by the connector. | `string` | `null` | no |
| <a name="input_scan_regions"></a> [scan\_regions](#input\_scan\_regions) | List of regions that will be opted into workload scanning. If empty, all regions will be opted in | `set(string)` | `[]` | no |
| <a name="input_scheduled_scanning_settings"></a> [scheduled\_scanning\_settings](#input\_scheduled\_scanning\_settings) | Map that contains the settings for scheduled security tool scanning.<br/>    enabled: Boolean that controls whether the scheduled security tool scanning is enabled or disabled<br/>    public\_buckets\_scanning\_enabled: Boolean that controls whether public buckets scanning is enabled or disabled | <pre>object({<br/>    enabled                         = optional(bool, true)<br/>    public_buckets_scanning_enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_skip_organization_scan"></a> [skip\_organization\_scan](#input\_skip\_organization\_scan) | Boolean that controls whether the connector is scoped to a single account or an organization | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the connector that was created |
| <a name="output_name"></a> [name](#output\_name) | Name of the connector that was created |
| <a name="output_outpost_id"></a> [outpost\_id](#output\_outpost\_id) | ID of the Wiz Outpost that was used for this connector |
<!-- END_TF_DOCS -->
