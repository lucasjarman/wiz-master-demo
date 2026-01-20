<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.11.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.11.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.1 |

## Resources

| Name | Type |
|------|------|
| [aws_bcmdataexports_export.wiz_cost_export](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bcmdataexports_export) | resource |
| [aws_iam_policy.wiz_allow_cost_export_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.wiz_access_role_exports_by_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.wiz_access_role_exports_by_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.wiz_cost_export_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.cost_and_usage_export_s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [random_id.uniq](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cost_and_usage_export_s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.wiz_cost_and_usage_report_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_new_export"></a> [create\_new\_export](#input\_create\_new\_export) | Whether to create a new cost export or use an existing one. | `bool` | n/a | yes |
| <a name="input_cost_export_bucket"></a> [cost\_export\_bucket](#input\_cost\_export\_bucket) | The name bucket to which the cost export will be saved. Don't fill if you want to create a new bucket. | `string` | `""` | no |
| <a name="input_cost_export_name"></a> [cost\_export\_name](#input\_cost\_export\_name) | The name of the cost export. | `string` | `"Wiz-Cloud-Cost-Export"` | no |
| <a name="input_cost_exports_prefix"></a> [cost\_exports\_prefix](#input\_cost\_exports\_prefix) | The S3 prefix for the cost export files. | `string` | `"Wiz"` | no |
| <a name="input_wiz_access_role_arn"></a> [wiz\_access\_role\_arn](#input\_wiz\_access\_role\_arn) | The ARN of the AWS role used by the Wiz cloud connector. | `string` | `""` | no |
| <a name="input_wiz_access_role_arns"></a> [wiz\_access\_role\_arns](#input\_wiz\_access\_role\_arns) | List of the arns of the AWS roles used by the Wiz cloud connector. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | n/a |
| <a name="output_cost_export_name"></a> [cost\_export\_name](#output\_cost\_export\_name) | n/a |
| <a name="output_cost_export_prefix"></a> [cost\_export\_prefix](#output\_cost\_export\_prefix) | n/a |
| <a name="output_cost_policy_arn"></a> [cost\_policy\_arn](#output\_cost\_policy\_arn) | n/a |
<!-- END_TF_DOCS -->
