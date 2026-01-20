# simple

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.10.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0.0 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | ~> 1.8 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_wiz"></a> [wiz](#module\_wiz) | https://s3-us-east-2.amazonaws.com/wizio-public/deployment-v2/aws/wiz-aws-native-terraform-terraform-module.zip | n/a |
| <a name="module_wiz_connector"></a> [wiz\_connector](#module\_wiz\_connector) | ../../ | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the connector that was created |
| <a name="output_name"></a> [name](#output\_name) | Name of the connector that was created |
| <a name="output_outpost_id"></a> [outpost\_id](#output\_outpost\_id) | ID of the Wiz Outpost that was used for this connector |
| <a name="output_wiz_role_arn"></a> [wiz\_role\_arn](#output\_wiz\_role\_arn) | ARN that was created that will be used by the Wiz connector |
<!-- END_TF_DOCS -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0.0 |
| <a name="requirement_wiz"></a> [wiz](#requirement\_wiz) | >= 1.8 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_wiz"></a> [wiz](#module\_wiz) | https://s3-us-east-2.amazonaws.com/wizio-public/deployment-v2/aws/wiz-aws-native-terraform-terraform-module.zip | n/a |
| <a name="module_wiz_connector"></a> [wiz\_connector](#module\_wiz\_connector) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the connector that was created |
| <a name="output_name"></a> [name](#output\_name) | Name of the connector that was created |
| <a name="output_outpost_id"></a> [outpost\_id](#output\_outpost\_id) | ID of the Wiz Outpost that was used for this connector |
| <a name="output_wiz_role_arn"></a> [wiz\_role\_arn](#output\_wiz\_role\_arn) | ARN that was created that will be used by the Wiz connector |
<!-- END_TF_DOCS -->
