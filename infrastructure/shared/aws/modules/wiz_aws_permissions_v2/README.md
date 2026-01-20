# wiz_aws_permissions_v2

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.83 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.83 |
| <a name="provider_http"></a> [http](#provider\_http) | ~> 3.5 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.wiz_full_policy2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.wiz_merged_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.user_role_tf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.wiz_full_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.security_audit_role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.view_only_access_role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.wiz_full_policy2_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.wiz_merged_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [http_http.wiz_policies](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Connector External ID | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name to give the Wiz role | `string` | n/a | yes |
| <a name="input_enable_cloud_cost_scanning"></a> [enable\_cloud\_cost\_scanning](#input\_enable\_cloud\_cost\_scanning) | Enable Cloud Cost scanning | `bool` | `true` | no |
| <a name="input_enable_data_scanning"></a> [enable\_data\_scanning](#input\_enable\_data\_scanning) | Enable DSPM data scanning | `bool` | `false` | no |
| <a name="input_enable_defend_scanning"></a> [enable\_defend\_scanning](#input\_enable\_defend\_scanning) | Enable Defend scanning | `bool` | `false` | no |
| <a name="input_enable_eks_scanning"></a> [enable\_eks\_scanning](#input\_enable\_eks\_scanning) | Enable EKS scanning | `bool` | `false` | no |
| <a name="input_enable_lightsail_scanning"></a> [enable\_lightsail\_scanning](#input\_enable\_lightsail\_scanning) | Enable Lightsail scanning | `bool` | `false` | no |
| <a name="input_enable_terraform_bucket_scanning"></a> [enable\_terraform\_bucket\_scanning](#input\_enable\_terraform\_bucket\_scanning) | Enable Terraform Bucket scanning | `bool` | `true` | no |
| <a name="input_permission_boundary_arn"></a> [permission\_boundary\_arn](#input\_permission\_boundary\_arn) | Optional - ARN of the policy that is used to set the permissions boundary for the role. | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for the policy name | `string` | `"standard-connector"` | no |
| <a name="input_remote_arn"></a> [remote\_arn](#input\_remote\_arn) | Enter the AWS Trust Policy Role ARN for your Wiz data center. You can retrieve it from User Settings, Tenant in the Wiz portal | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_wiz_standard_connector_url"></a> [wiz\_standard\_connector\_url](#input\_wiz\_standard\_connector\_url) | URL for the Wiz standard connector policies | `string` | `"https://downloads.wiz.io/customer-files/aws/standard_connector_tf.json"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_enabled_policy_types"></a> [enabled\_policy\_types](#output\_enabled\_policy\_types) | List of enabled policy types |
| <a name="output_latest_policy_modification_date"></a> [latest\_policy\_modification\_date](#output\_latest\_policy\_modification\_date) | Latest modification date of the policies |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | Wiz Access Role ARN |
<!-- END_TF_DOCS -->
